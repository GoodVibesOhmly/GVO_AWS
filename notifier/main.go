package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws/session"
	log "github.com/sirupsen/logrus"

	"github.com/opolis/deployer/pipeline"
	"github.com/opolis/deployer/repo"
	"github.com/opolis/deployer/secure"
	"github.com/opolis/deployer/types"
)

func init() {
	log.SetFormatter(&log.JSONFormatter{DisableTimestamp: true})
}

func main() {
	lambda.Start(Handler)
}

// Handler serves as the integration point between the AWS event and business logic by
// preparing conrete types to satisfy the Process interface.
func Handler(event events.CloudWatchEvent) error {
	defer func() {
		if r := recover(); r != nil {
			log.Errorln("recovered from panic:", r)
		}
	}()

	// AWS session
	sess := session.Must(session.NewSession())

	// Pull the pipeline event detail
	var detail types.PipelineStageDetail
	if err := json.Unmarshal(event.Detail, &detail); err != nil {
		log.Errorln("json.Unmarshal:", err.Error())
		return nil
	}

	// fetch secure repo token
	secureStore := secure.NewAWSSecureStore(sess)
	token, err := secureStore.Get(types.KeyToken)
	if err != nil {
		log.Errorln("parameter.Get:", err.Error())
		return nil
	}

	// Create the pipeline manager and repository
	manager := pipeline.NewAWSPipelineManager(sess)
	owner, repoName, err := manager.GetRepoInfo(detail.Pipeline)
	if err != nil {
		log.Errorln("error getting repo info:", err.Error())
		return nil
	}

	log := log.WithFields(log.Fields{"pipeline": detail.Pipeline})
	repo := repo.NewGitHubRepository(log, owner, repoName, token)

	if err := Process(detail, manager, repo); err != nil {
		log.Errorln("error processing:", err.Error())
		return nil
	}

	return nil
}

// Process reads the pipeline event detail and writes a status back to the
// source repository.
func Process(detail types.PipelineStageDetail, manager types.PipelineManager, repo types.Repository) error {
	// get current revision
	revision, err := manager.GetRevision(detail.ExecutionId, detail.Pipeline)
	if err != nil {
		return err
	}

	// update status
	status := types.GitHubStatus{
		State:     mapState(detail.State),
		TargetUrl: statusUrl(detail.Pipeline),
		Context:   "pipeline/" + detail.Stage,
	}

	return repo.Status(revision, status)
}

//
// Helpers
//

func statusUrl(pipeline string) string {
	return fmt.Sprintf(
		"https://%s.console.aws.amazon.com/codepipeline/home#/view/%s",
		os.Getenv("AWS_REGION"),
		pipeline,
	)
}

func mapState(state string) string {
	if state == types.PipelineStateStarted {
		return types.GitStatePending

	} else if state == types.PipelineStateResumed {
		return types.GitStatePending

	} else if state == types.PipelineStateSucceeded {
		return types.GitStateSuccess
	}

	return types.GitStateFailure
}

IMAGE = opolis/build:dev
GOPATH = /go/src/github.com/opolis/build
FUNC=nothing

RUN = docker run -it --rm \
	  -v $(HOME)/.aws:/root/.aws \
	  -v $(PWD):$(GOPATH) \
	  -v $(PWD)/.cache:/root/.cache/go-build \
	  -w $(GOPATH) \
	  $(IMAGE)

COMPILE = env GOOS=linux go build -ldflags="-s -w"

.PHONY: image
image:
	@docker build -t $(IMAGE) .

.PHONY: deps
deps:
	@$(RUN) dep ensure

.PHONY: build
build:
	@mkdir -p bin/lib
	@$(RUN) $(COMPILE) -o bin/builder builder/main.go
	@$(RUN) $(COMPILE) -o bin/listener listener/main.go
	@$(RUN) $(COMPILE) -o bin/notifier notifier/main.go
	@$(RUN) $(COMPILE) -o bin/lib/ecs-watcher lib/ecs-watcher/main.go
	@$(RUN) $(COMPILE) -o bin/lib/s3deployer lib/s3deployer/main.go
	@$(RUN) $(COMPILE) -o bin/lib/s3cleaner lib/s3cleaner/main.go
	@$(RUN) $(COMPILE) -o bin/lib/slack-notifier lib/slack-notifier/main.go
	@$(RUN) $(COMPILE) -o bin/lib/stack-cleaner lib/stack-cleaner/main.go

.PHONY: build-func
build-func:
	@$(RUN) $(COMPILE) -o bin/$(FUNC) $(FUNC)/main.go

.PHONY: deploy
deploy:
	@$(RUN) serverless --stage dev deploy

.PHONY: shell
shell:
	@$(RUN) sh

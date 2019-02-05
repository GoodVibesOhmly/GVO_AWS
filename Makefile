IMAGE = opolis/build:build
GOPATH = /go/src/github.com/opolis/build
FUNC = nothing

RUN = docker run -it --rm \
	  -v $(HOME)/.aws:/root/.aws \
	  -v $(PWD):$(GOPATH) \
	  -v $(PWD)/.cache:/root/.cache/go-build \
	  -w $(GOPATH) \
	  $(IMAGE)

# Compilation flags for AWS Lambda
COMPILE = env GOOS=linux go build -ldflags="-s -w"

.PHONY: image
image:
	@docker build --no-cache -t $(IMAGE) .

.PHONY: deps
deps:
	@$(RUN) dep ensure -v

.PHONY: build
build:
	@mkdir -p bin/lib
	@echo 'Building builder...'
	@$(RUN) $(COMPILE) -o bin/builder builder/main.go
	@echo 'Building listener...'
	@$(RUN) $(COMPILE) -o bin/listener listener/main.go
	@echo 'Building notifier...'
	@$(RUN) $(COMPILE) -o bin/notifier notifier/main.go
	@echo 'Building lib/s3cleaner...'
	@$(RUN) $(COMPILE) -o bin/lib/s3cleaner lib/s3cleaner/main.go
	@echo 'Building lib/s3deployer...'
	@$(RUN) $(COMPILE) -o bin/lib/s3deployer lib/s3deployer/main.go
	@echo 'Building lib/stack-cleaner...'
	@$(RUN) $(COMPILE) -o bin/lib/stack-cleaner lib/stack-cleaner/main.go
	@echo 'Done!'

.PHONY: config-cli
config-cli:
	@$(RUN) env GOOS=darwin go build -o opolis-build-config-macos -ldflags="-s -w" cli/config/main.go

.PHONY: build-func
build-func:
	@$(RUN) $(COMPILE) -o bin/$(FUNC) $(FUNC)/main.go

.PHONY: deploy
deploy:
	@$(RUN) serverless --stage prod deploy

.PHONY: deploy-dev
deploy-dev:
	@$(RUN) serverless --stage dev deploy

.PHONY: shell
shell:
	@$(RUN) sh

# Multi-cloud canary deployment on serverless platforms

Ever wondered how you _actually_ do gradual canary rollouts with AWS, Azure or GCP's serverless platforms? Look no further.

This demo uses a small webserver as the demo application.

Deployed and demonstrated on your choice of:

- Google Cloud Platform: [Cloud Run](https://cloud.google.com/run)
- Azure: [Azure Functions](https://azure.microsoft.com/en-us/services/functions/)
- Amazon Web Services: [Lambda](https://aws.amazon.com/lambda/)

## Instructions

You will need to have any required access rights in your cloud of choice, and credentials need to be available so the tooling can work properly.

**Before doing anything, please verify, read, and update any scripts you will run. Some may require that you take them bit-by-bit rather than running them in one go.**

### Install

Run `npm install` or `yarn install` in the root.

### Local development

#### AWS

Run `npm run dev:aws`.

#### Azure

Run `npm run dev:aws`.

#### GCP

Run `npm run dev:aws`.

### Initialize project

#### AWS

Does not need initializing. You will need to have access rights and so on, however.

#### Azure

Run `npm run init:azure`.

#### GCP

Run `npm run init:gcp`.

### Deploy project

#### AWS

Run `npm run deploy:aws`.

#### Azure

Run `npm run deploy:azure`.

#### GCP

Run `npm run deploy:gcp`.

### Teardown (remove) project

#### AWS

Run `npm run teardown:aws`.

#### Azure

Run `npm run teardown:azure`.

#### GCP

Run `npm run teardown:gcp`.

### How to use the example application

On the root path, it will respond with `Hello World!` and status 200.

For GCP, you can add `/warn`, `/error` and `/throw` to run console warn's, errors or throw errors.

For Azure and AWS, it's the same thing but with query parameters, so `{URL}?warn`, `{URL}?error`, and `{URL}?throw`.

You can try out the canary "rollback/failure" by causing an error when you are in the deployment process.

## Phases

These apply to the Google Cloud Platform version, but are more or less the same in the setup for Azure.

1. `Identity`: Echo various identity variables
2. `Install`: Install dependencies
3. `Test`: Test application
4. (`Package`) and `Deploy`: Run deployment step, start with no public traffic
5. `Wait`: Add a bit of wait time to let the deployment settle
6. `SmokeTest`: Run a basic smoke test (can be extended through, for example, a dedicated testing suite or a script)
7. `CheckErrors`: Check logs for errors
8. `Rollout50Percent`: Add production traffic
9. `Wait50Percent`: Wait for a period of time to let the canary service be used
10. `CheckErrors50Percent`: Check logs for errors
11. `UpdateTag`: If no errors, update the tag from "canary" to "latest"
12. `Release`: Switch over all traffic to the latest service revision

### How about testing if we have a lot of infrastructure?

Using Serverless Framework (or ARM, CloudFormation, Deployment Manager, Terraform...) you could add your infra stack (for example `serverless.infra.yml`) and deploy that separately (perhaps with a unique, temporary ID) before the `Deploy` step. If you'd then encounter an error, you simply remove/teardown the stack together with the application. The process is therefore more or less the same with infra as it would be with "only" an app.

## Solution specifics

For 2 out of 3 solutions, Serverless Framework is used as a deployment convenience. There is nothing magical or special about it, and with a bit of quick hands you should be able to migrate that to your own deployment tool in no time.

### Google Cloud Platform

Uses Cloud Build and a `gcloud` deployment of the application to Cloud Run. Cloud Run is similar, but not exactly the same, as Cloud Functions. Cloud Run is an improvement in many ways, but since its level of abstraction is a "container" rather than a "function", it's not strictly cut from the same cloth as Azure Functions and AWS Lambda.

Because it runs in a container, Cloud Run also lacks any "API-like" routing, which we will replicate with a basic Express router (in the `/src` folder).

The main reason for Cloud Run over Cloud Functions is that Cloud Run offers traffic management through the `gcloud` API, without which it's going to be very hard to do gradual rollouts without using the DNS/network layer (Hint: we don't want that).

For the above reasons, as opposed to the other examples, Serverless Framework is not used.

#### Before the first deployment

Before you deploy, ensure that version numbers in `gcp/scripts/init.sh` under the comment `Remove junk you won't need` are correct with those in `package.json`. That entire block is added to reduce any non-GCP junk.

Also, remove the line that includes `--no-traffic` for deployment in `gcp/pipeline/cloudbuild.yaml` for the first run, as it's not supported for a brand new service.

Finally, update `_CANARY_URL` in `gcp/pipeline/cloudbuild.yaml` to your canary URL (looks like `https://canary---webserver-${RANDOM_STRING}.a.run.app`).

### Amazon Web Services

Uses Serverless Framework to deploy the application, with CodeDeploy under the hood to manage traffic and check for any reported errors.

This variant is simplified versus the other two. This does not use a specific CI script (but you could do steps in for example CodeBuild), because there is already fairly good "off-the-shelf" support with Serverless Framework and the few plugins needed to get canaries working.

The canary will first receive 10% of all traffic, then after 5 minutes (if no errors are reported), it will get all traffic routed to it. While deploying, you can see additional information in the CodeDeploy view in the AWS console.

This approach uses [serverless-plugin-canary-deployments](https://github.com/davidgf/serverless-plugin-canary-deployments) and [serverless-plugin-aws-alerts](https://github.com/ACloudGuru/serverless-plugin-aws-alerts).

### Azure Functions

Uses Serverless Framework to package the application and Azure DevOps with the `az` CLI to actually deploy the application. The Function app uses "deployment slots" to manage traffic, which Serverless Framework does not currently support.

The approach used here is very similar to what I've used at [https://github.com/mikaelvesavuori/azure-build-deploy-release-demo](https://github.com/mikaelvesavuori/azure-build-deploy-release-demo) previously.

Serverless ("Consumption") plans offer a single deployment slot, but it won't offer traffic redirection. You'd need to have a regular App Service plan (like Standard) instead, which will cost you per hour rather than per request. Read more at [https://medium.com/faun/azure-functions-slots-guide-1557814facc3](https://medium.com/faun/azure-functions-slots-guide-1557814facc3) and [https://docs.microsoft.com/en-us/azure/azure-functions/functions-deployment-slots](https://docs.microsoft.com/en-us/azure/azure-functions/functions-deployment-slots). You could certainly use the secondary slot just fine for integration and smoke testing, but you can't do "easy" built-in CLI-powered traffic redirection without resorting to routing more/less traffic from the DNS/network layer (for example with Azure Traffic Manager).

You will also need to manually create a service connection (Azure RM, 'automatic' type) called `service-connection-arm-pipeline` and authorize it after running your first deployment.

## Permissions

You will need to give your Cloud Build service account rights to access Logging.

## References

### Blue/green and canary

- https://thenewstack.io/primer-blue-green-deployments-and-canary-releases/
- https://stackoverflow.com/questions/23746038/canary-release-strategy-vs-blue-green
- https://dev.to/mostlyjason/intro-to-deployment-strategies-blue-green-canary-and-more-3a3
- https://harness.io/blog/continuous-verification/blue-green-canary-deployment-strategies/
- https://semaphoreci.com/blog/what-is-canary-deployment

### AWS

- https://www.serverless.com/blog/manage-canary-deployments-lambda-functions-serverless-framework
- https://docs.aws.amazon.com/whitepapers/latest/modern-application-development-on-aws/canary-deployments-to-aws-lambda.html

### Azure

- https://docs.microsoft.com/en-us/cli/azure/monitor?view=azure-cli-latest
- https://docs.microsoft.com/en-us/azure/azure-monitor/samples/cli-samples
- https://docs.microsoft.com/en-us/azure/container-instances/container-instances-image-security
- https://azure.microsoft.com/en-us/blog/blue-green-deployments-using-azure-traffic-manager/
- https://github.com/nhsuk/apim-blue-green-deploy
- https://azapril.dev/2020/07/28/managing-application-delivery-with-azure-devops-and-a-b-testing-in-azure-webapps/
- https://borzenin.com/blue-green-azure-front-door/
- https://azure.github.io/AppService/2020/07/07/zero_to_hero_pt3.html
- https://stackoverflow.com/questions/61519906/azure-app-service-canary-deployment-through-pipeline
- https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/utility/bash?view=azure-devops
- https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops
- https://docs.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops
- https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops

### GCP

- https://cloud.google.com/sdk/gcloud/reference/logging/read
- https://cloud.google.com/run/docs/logging
- https://cloud.google.com/run/docs/audit-logging
- https://github.com/GoogleCloudPlatform/cloud-run-release-manager
- https://github.com/ahmetb/cloud-run-faq#how-to-do-canary-or-bluegreen-deployments-on-cloud-run
- https://dev.to/zenika/deploying-your-spring-boot-application-in-cloud-run-59i4
- https://dev.to/zenika/continuous-deployment-pipeline-with-cloud-build-on-cloud-run-40a2
- https://cloud.google.com/cloud-build/docs/speeding-up-builds
- https://cloud.google.com/cloud-build/docs/kaniko-cache
- https://cloud.google.com/kubernetes-engine/docs/tutorials/gitops-cloud-build
- https://cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration
- https://cloud.google.com/cloud-build/docs/configuring-builds/run-bash-scripts
- https://cloud.google.com/sdk/gcloud/reference/beta/run/deploy
- https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
- https://cloud.google.com/build/docs/configuring-builds/substitute-variable-values

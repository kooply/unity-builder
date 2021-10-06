import CloudRunnerLogger from '../services/cloud-runner-logger';
import { CloudRunnerState } from '../state/cloud-runner-state';
import { CloudRunnerStepState } from '../state/cloud-runner-step-state';
import { BuildStep } from '../steps/build-step';
import { CompressionStep } from '../steps/compression-step';
import { DownloadRepositoryStep } from '../steps/download-repository-step';
import { CustomWorkflow } from './custom-workflow';
import { WorkflowInterface } from './workflow-interface';

export class BuildAutomationWorkflow implements WorkflowInterface {
  async run(cloudRunnerStepState: CloudRunnerStepState) {
    await BuildAutomationWorkflow.standardBuildAutomation(cloudRunnerStepState.image);
  }

  private static async standardBuildAutomation(baseImage: any) {
    CloudRunnerLogger.log(`Cloud Runner is running standard build automation`);

    await new DownloadRepositoryStep().run(
      new CloudRunnerStepState(
        'alpine/git',
        CloudRunnerState.readBuildEnvironmentVariables(),
        CloudRunnerState.defaultSecrets,
      ),
    );
    CloudRunnerLogger.logWithTime('Download repository step time');

    await CustomWorkflow.runCustomJob(CloudRunnerState.buildParams.preBuildSteps);
    CloudRunnerLogger.logWithTime('Pre build step(s) time');

    new BuildStep().run(
      new CloudRunnerStepState(
        baseImage,
        CloudRunnerState.readBuildEnvironmentVariables(),
        CloudRunnerState.defaultSecrets,
      ),
    );
    CloudRunnerLogger.logWithTime('Build time');

    await new CompressionStep().run(
      new CloudRunnerStepState(
        'alpine',
        CloudRunnerState.readBuildEnvironmentVariables(),
        CloudRunnerState.defaultSecrets,
      ),
    );
    CloudRunnerLogger.logWithTime('Compression time');

    await CustomWorkflow.runCustomJob(CloudRunnerState.buildParams.postBuildSteps);
    CloudRunnerLogger.logWithTime('Post build step(s) time');

    CloudRunnerLogger.log(`Cloud Runner finished running standard build automation`);
  }
}
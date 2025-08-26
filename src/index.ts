import * as core from '@actions/core';
import { Action, BuildParameters, Cache, CloudRunner, Docker, ImageTag, Output } from './model';
import { Cli } from './model/cli/cli';
import MacBuilder from './model/mac-builder';
import PlatformSetup from './model/platform-setup';

async function runMain() {
  try {
    if (Cli.InitCliMode()) {
      await Cli.RunCli();

      return;
    }
    Action.checkCompatibility();
    Cache.verify();

    const { workspace, actionFolder } = Action;

    core.info('🔍 Starting BuildParameters.create()...');
    const buildParameters = await BuildParameters.create();
    core.info('✅ BuildParameters.create() completed');

    core.info('🔍 Creating ImageTag...');
    const baseImage = new ImageTag(buildParameters);
    core.info('✅ ImageTag created');

    let exitCode = -1;

    if (buildParameters.providerStrategy === 'local') {
      core.info('Building locally');
      core.info('🔍 Starting PlatformSetup.setup()...');
      await PlatformSetup.setup(buildParameters, actionFolder);
      core.info('✅ PlatformSetup.setup() completed');
      exitCode =
        process.platform === 'darwin'
          ? await MacBuilder.run(actionFolder)
          : await Docker.run(baseImage.toString(), {
              workspace,
              actionFolder,
              ...buildParameters,
            });
    } else {
      await CloudRunner.run(buildParameters, baseImage.toString());
      exitCode = 0;
    }

    // Set output
    await Output.setBuildVersion(buildParameters.buildVersion);
    await Output.setAndroidVersionCode(buildParameters.androidVersionCode);
    await Output.setEngineExitCode(exitCode);

    if (exitCode !== 0) {
      core.setFailed(`Build failed with exit code ${exitCode}`);
    }
  } catch (error) {
    core.setFailed((error as Error).message);
  }
}

runMain();

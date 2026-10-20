import { describe, it, expect, vi, beforeEach, afterEach, beforeAll, afterAll, test } from 'vitest';
import { mkdtempSync, rmSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import Action from './action';
import Docker from './docker';

describe('Docker', () => {
  it.skip('runs', async () => {
    const image = 'unity-builder:2019.2.11f1-webgl';
    const parameters = {
      workspace: Action.rootFolder,
      projectPath: `${Action.rootFolder}/test-project`,
      buildName: 'someBuildName',
      buildsPath: 'build',
      method: '',
    };
    await Docker.run(image, parameters);
  });

  describe('getLinuxCommand', () => {
    const signing = {
      ANDROID_KEYSTORE_BASE64: 'a2V5c3RvcmUtYmFzZTY0',
      ANDROID_KEYSTORE_PASS: 'keystore-pass-value',
      ANDROID_KEYALIAS_NAME: 'keyalias-name-value',
      ANDROID_KEYALIAS_PASS: 'keyalias-pass-value',
    };
    let runnerTempPath: string;

    beforeEach(() => {
      runnerTempPath = mkdtempSync(path.join(os.tmpdir(), 'docker-test-'));
    });

    afterEach(() => {
      rmSync(runnerTempPath, { recursive: true, force: true });
      for (const name of Object.keys(signing)) delete process.env[name];
    });

    it('passes Android signing secrets by name, so the logged command holds none of their values', () => {
      const command = Docker.getLinuxCommand('unityci/editor', {
        runnerTempPath,
        androidKeystoreBase64: signing.ANDROID_KEYSTORE_BASE64,
        androidKeystorePass: signing.ANDROID_KEYSTORE_PASS,
        androidKeyaliasName: signing.ANDROID_KEYALIAS_NAME,
        androidKeyaliasPass: signing.ANDROID_KEYALIAS_PASS,
      });

      for (const [name, value] of Object.entries(signing)) {
        expect(command).toMatch(new RegExp(`--env ${name}\\s`));
        expect(command).not.toContain(value);
        expect(process.env[name]).toBe(value);
      }
    });
  });
});

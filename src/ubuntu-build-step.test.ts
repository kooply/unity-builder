import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { spawnSync } from 'node:child_process';
import { chmodSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

// Runs dist/platforms/ubuntu/steps/build.sh as runsteps.sh does (sourced in bash), with a stub unity-editor.
const buildScript = path.join(process.cwd(), 'dist/platforms/ubuntu/steps/build.sh');

// Unity's lines from Dash 4.96 RC1, where a duplicate font GUID across two git packages dropped the font (D2802).
const duplicateGuidLog = [
  "GUID [0cd985505eeb347418d1d423bcef1daa] for asset 'Packages/com.kooply.unity-common/Runtime/fonts/Lilita One/Lilita One Regular New SDF.asset.meta' conflicts with:",
  "  'Packages/com.kooply.unity/Modules/Common/Fonts/_Resources/LilitaOne/Lilita One Regular New SDF.asset.meta'",
  "We can't assign a new GUID because the asset is in an immutable folder. The asset will be ignored.",
].join('\n');
const cleanLog = 'Build Finished, Result: Success.';

describe('ubuntu build step', () => {
  let temporary: string;

  beforeEach(() => {
    temporary = mkdtempSync(path.join(os.tmpdir(), 'build-step-'));
    mkdirSync(path.join(temporary, 'bin'));
    mkdirSync(path.join(temporary, 'workspace/project'), { recursive: true });
    mkdirSync(path.join(temporary, 'failing-mktemp'));
    const editor = path.join(temporary, 'bin/unity-editor');
    writeFileSync(editor, '#!/usr/bin/env bash\nprintf "%s\\n" "$STUB_LOG"\nexit "$STUB_EXIT"\n');
    chmodSync(editor, 0o755);
    const mktemp = path.join(temporary, 'failing-mktemp/mktemp');
    writeFileSync(mktemp, '#!/usr/bin/env bash\nexit 1\n');
    chmodSync(mktemp, 0o755);
  });

  afterEach(() => rmSync(temporary, { recursive: true, force: true }));

  const build = (log: string, editorExitCode: number, captureFails = false) => {
    const stubs = [
      path.join(temporary, 'bin'),
      ...(captureFails ? [path.join(temporary, 'failing-mktemp')] : []),
    ];
    const result = spawnSync('bash', ['-c', 'source "$BUILD_SCRIPT"; exit "$BUILD_EXIT_CODE"'], {
      env: {
        PATH: `${stubs.join(':')}:${process.env.PATH}`,
        TMPDIR: temporary,
        GITHUB_WORKSPACE: path.join(temporary, 'workspace'),
        PROJECT_PATH: 'project',
        BUILD_PATH: 'build',
        BUILD_TARGET: 'Android',
        BUILD_METHOD: 'Stub.Build',
        BUILD_SCRIPT: buildScript,
        STUB_LOG: log,
        STUB_EXIT: String(editorExitCode),
      },
      encoding: 'utf8',
    });

    return { exitCode: result.status, stdout: result.stdout };
  };

  it('fails a build whose Unity log ignores an asset in an immutable package', () => {
    const { exitCode, stdout } = build(duplicateGuidLog, 0);

    expect(exitCode).toBe(1);
    expect(stdout).toContain(duplicateGuidLog);
  });

  it('passes a clean build', () => {
    expect(build(cleanLog, 0).exitCode).toBe(0);
  });

  it("fails a build whose Unity log could not be captured, so the check can't pass by default", () => {
    expect(build(duplicateGuidLog, 0, true).exitCode).toBe(1);
    expect(build(cleanLog, 0, true).exitCode).toBe(1);
  });

  it("keeps Unity's own failure code", () => {
    expect(build(cleanLog, 3).exitCode).toBe(3);
    expect(build(duplicateGuidLog, 3).exitCode).toBe(3);
    expect(build(cleanLog, 3, true).exitCode).toBe(3);
  });
});

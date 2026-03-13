import test from 'node:test';
import assert from 'node:assert';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import os from 'node:os';

// Mock defineEventHandler before importing the handler
(globalThis as any).defineEventHandler = (handler: any) => handler;

// Import the handler
import handler from './project-list.ts';

test('project-list API', async (t) => {
  const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'nuxt-api-test-'));
  const originalCwd = process.cwd();

  const siteDir = path.join(tmpDir, 'site');
  const projectsDir = path.join(tmpDir, 'projects');
  await fs.mkdir(siteDir);
  await fs.mkdir(projectsDir);

  process.chdir(siteDir);

  t.after(async () => {
    process.chdir(originalCwd);
    await fs.rm(tmpDir, { recursive: true, force: true });
  });

  await t.test('returns empty list when no projects exist', async () => {
    const result = await (handler as any)({});
    assert.deepStrictEqual(result, []);
  });

  await t.test('returns published projects', async () => {
    const projectA = path.join(projectsDir, 'project-a');
    await fs.mkdir(projectA);
    await fs.writeFile(
      path.join(projectA, 'project.json'),
      JSON.stringify({ name: 'Project A', publish: true })
    );

    const projectB = path.join(projectsDir, 'project-b');
    await fs.mkdir(projectB);
    await fs.writeFile(
      path.join(projectB, 'project.json'),
      JSON.stringify({ name: 'Project B', publish: false })
    );

    const result = await (handler as any)({});
    assert.strictEqual(result.length, 1);
    assert.strictEqual(result[0].name, 'Project A');
    assert.strictEqual(result[0]._slug, 'project-a');
  });

  await t.test('sorts projects by updatedAt descending', async () => {
    // Clear projectsDir for clean state
    const entries = await fs.readdir(projectsDir);
    for (const entry of entries) {
      await fs.rm(path.join(projectsDir, entry), { recursive: true });
    }

    const projectOld = path.join(projectsDir, 'old');
    await fs.mkdir(projectOld);
    const oldJson = path.join(projectOld, 'project.json');
    await fs.writeFile(oldJson, JSON.stringify({ name: 'Old', publish: true }));
    const oldTime = new Date('2020-01-01T00:00:00Z');
    await fs.utimes(oldJson, oldTime, oldTime);

    const projectNew = path.join(projectsDir, 'new');
    await fs.mkdir(projectNew);
    const newJson = path.join(projectNew, 'project.json');
    await fs.writeFile(newJson, JSON.stringify({ name: 'New', publish: true }));
    const newTime = new Date('2023-01-01T00:00:00Z');
    await fs.utimes(newJson, newTime, newTime);

    const result = await (handler as any)({});
    assert.strictEqual(result.length, 2);
    assert.strictEqual(result[0].name, 'New');
    assert.strictEqual(result[1].name, 'Old');
  });

  await t.test('detects downloads', async () => {
     // Clear projectsDir
    const entries = await fs.readdir(projectsDir);
    for (const entry of entries) {
      await fs.rm(path.join(projectsDir, entry), { recursive: true });
    }

    const projectZip = path.join(projectsDir, 'zipped');
    await fs.mkdir(projectZip);
    await fs.writeFile(
      path.join(projectZip, 'project.json'),
      JSON.stringify({ name: 'Zipped', publish: true })
    );

    const publicDownloads = path.join(siteDir, 'public/downloads');
    await fs.mkdir(publicDownloads, { recursive: true });
    await fs.writeFile(path.join(publicDownloads, 'zipped.zip'), 'dummy content');

    const result = await (handler as any)({});
    assert.strictEqual(result.length, 1);
    assert.strictEqual(result[0].hasDownload, true);

    const projectNoZip = path.join(projectsDir, 'no-zip');
    await fs.mkdir(projectNoZip);
    await fs.writeFile(
      path.join(projectNoZip, 'project.json'),
      JSON.stringify({ name: 'No Zip', publish: true })
    );

    const result2 = await (handler as any)({});
    assert.strictEqual(result2.length, 2);
    const noZip = result2.find((p: any) => p._slug === 'no-zip');
    assert.strictEqual(noZip.hasDownload, false);
  });

  await t.test('handles invalid project.json', async () => {
    const invalidDir = path.join(projectsDir, 'invalid');
    await fs.mkdir(invalidDir);
    await fs.writeFile(path.join(invalidDir, 'project.json'), 'invalid json');

    // Should not throw and just skip
    const result = await (handler as any)({});
    const invalid = result.find((p: any) => p._slug === 'invalid');
    assert.strictEqual(invalid, undefined);
  });
});

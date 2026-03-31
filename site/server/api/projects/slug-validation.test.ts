
import { test } from 'node:test';
import assert from 'node:assert';

// Mocking the environment and functions used in the handler
const getRouterParam = (event, param) => event.params[param];
const createError = (error) => {
  const err = new Error(error.statusMessage);
  err.statusCode = error.statusCode;
  return err;
};

// Simplified version of the handler logic for testing validation
const validateSlug = (slug) => {
  if (!slug || !/^[a-zA-Z0-9_-]+$/.test(slug)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid project slug',
    });
  }
  return true;
};

test('slug validation allows safe slugs', () => {
  assert.strictEqual(validateSlug('my-project'), true);
  assert.strictEqual(validateSlug('project_123'), true);
  assert.strictEqual(validateSlug('SimpleProject'), true);
});

test('slug validation blocks command injection attempts', () => {
  assert.throws(() => validateSlug('project; ls'), /Invalid project slug/);
  assert.throws(() => validateSlug('project && cat /etc/passwd'), /Invalid project slug/);
  assert.throws(() => validateSlug('project | grep something'), /Invalid project slug/);
  assert.throws(() => validateSlug('`whoami`'), /Invalid project slug/);
  assert.throws(() => validateSlug('$(whoami)'), /Invalid project slug/);
});

test('slug validation blocks path traversal attempts', () => {
  assert.throws(() => validateSlug('../other-project'), /Invalid project slug/);
  assert.throws(() => validateSlug('project/../../etc/passwd'), /Invalid project slug/);
});

test('slug validation blocks other unsafe characters', () => {
  assert.throws(() => validateSlug('project@name'), /Invalid project slug/);
  assert.throws(() => validateSlug('project!'), /Invalid project slug/);
  assert.throws(() => validateSlug('project space'), /Invalid project slug/);
});

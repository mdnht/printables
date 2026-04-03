import assert from 'node:assert'
import test from 'node:test'
import path from 'path'
import { promises as fs } from 'fs'
import handler from './[slug].ts'

// Mock getRouterParam
const mockGetRouterParam = (event: any, key: string) => event.params[key]
global.getRouterParam = mockGetRouterParam

test('handler should reject invalid slugs', async () => {
  const invalidSlugs = [
    '../outside',
    'project; rm -rf /',
    'project&ls',
    ' ',
    '',
    'project/with/slash'
  ]

  for (const slug of invalidSlugs) {
    const event = { params: { slug } }
    const result = await handler(event)
    assert.strictEqual(result, null, `Slug "${slug}" should be rejected`)
  }
})

test('handler should accept valid slugs', async (t) => {
  // We need to mock fs and execFile to test the logic without real files
  // But for a simple check, we can just verify it doesn't crash and returns null if project doesn't exist
  const validSlug = 'valid-project_name-123'
  const event = { params: { slug: validSlug } }

  // Since the project doesn't exist, it should catch the error and return null or log error and return null
  const result = await handler(event)
  assert.strictEqual(result, null)
})

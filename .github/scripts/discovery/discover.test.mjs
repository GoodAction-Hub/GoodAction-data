import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile, writeFile, mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { parse } from 'yaml';
import {
  canonicalUrl, validateCandidate, mergeActivities, appendActivities,
  postJson, expandQuery, selectSources, discover, main,
} from './discover.mjs';

const now = new Date('2026-11-05T00:00:00Z');
const source = {
  url: 'https://mp.weixin.qq.com/s/example?scene=1',
  raw_content: 'Community volunteer event. 2026-11-10 09:00:00 to 2026-11-10 17:00:00 at Shanghai library. Public welfare volunteering, free admission.',
};
const candidate = {
  title: 'Community volunteer event',
  description: 'A public welfare volunteering event.',
  category: 'meetup',
  tags: ['volunteer'],
  is_public_welfare: true,
  start_time: '2026-11-10 09:00:00',
  end_time: '2026-11-10 17:00:00',
  timezone: 'Asia/Shanghai',
  place: 'Shanghai library',
  evidence: {
    title: 'Community volunteer event',
    start_time: '2026-11-10 09:00:00',
    end_time: '2026-11-10 17:00:00',
    place: 'Shanghai library',
    public_welfare: 'Public welfare volunteering, free admission.',
  },
};
const activity = () => validateCandidate(structuredClone(candidate), source, now).activity;
const env = { TAVILY_API_KEY: 'test-search', OPENAI_API_KEY: 'test-model' };
const config = [{ channel: 'wechat', query: '{year} volunteering', domains: ['mp.weixin.qq.com'] }];
const extracted = (activities) => ({ choices: [{ message: { content: JSON.stringify({ activities }) } }] });

test('canonical URLs remove tracking but preserve WeChat article identity', () => {
  assert.equal(canonicalUrl(source.url), 'https://mp.weixin.qq.com/s/example');
  assert.equal(
    canonicalUrl('http://mp.weixin.qq.com/s?mid=12&__biz=abc&idx=1&sn=xyz&scene=3&chksm=123#wechat'),
    'https://mp.weixin.qq.com/s?__biz=abc&idx=1&mid=12&sn=xyz',
  );
  assert.notEqual(canonicalUrl('https://a.test/?id=1'), canonicalUrl('https://a.test/?id=2'));
  assert.throws(() => canonicalUrl('javascript:alert(1)'));
});

test('valid candidates use the source URL and deterministic generated IDs', () => {
  const result = activity();
  assert.match(result.events[0].id, /^auto-[a-f0-9]{20}$/);
  assert.equal(result.events[0].link, 'https://mp.weixin.qq.com/s/example');
  assert.deepEqual(result, activity());
});

test('rejects missing fields, unsupported types, bad dates and ungrounded evidence', () => {
  for (const change of [
    { is_public_welfare: false }, { title: '' }, { tags: [] }, { category: 'advertisement' },
    { timezone: 'not/a/timezone' }, { start_time: '2026-02-30 09:00:00' },
    { start_time: '2026-11-11 09:00:00' }, { end_time: '2025-11-10 17:00:00' },
    { end_time: '2026-11-10' }, { evidence: { ...candidate.evidence, place: 'Invented venue' } },
  ]) {
    assert.throws(() => validateCandidate({ ...candidate, ...change }, source, now));
  }
});

test('expiry is evaluated in the event timezone', () => {
  assert.doesNotThrow(() => validateCandidate(candidate, source, new Date('2026-11-10T08:59:59Z')));
  assert.throws(() => validateCandidate(candidate, source, new Date('2026-11-10T09:00:01Z')));
});

test('deduplicates by ID, normalized title/date, or canonical source/date', () => {
  const base = [activity()];
  const sameTitle = activity();
  sameTitle.events[0].id = 'another';
  sameTitle.events[0].link = 'https://another.test/repost';
  sameTitle.title = 'Community VOLUNTEER event!';
  const sameSource = activity();
  sameSource.events[0].id = 'third';
  sameSource.title = 'Different headline';
  assert.deepEqual(mergeActivities(base, [sameTitle, sameSource]), []);
  const nextDate = activity();
  nextDate.events[0].id = 'next-session';
  nextDate.events[0].start_time = '2026-11-12 09:00:00';
  assert.equal(mergeActivities(base, [nextDate]).length, 1);
  assert.equal(mergeActivities([], [activity(), activity()]).length, 1);
});

test('retains pending activities, without duplicating ones already merged', () => {
  const pending = activity();
  assert.equal(mergeActivities([], [pending]).length, 1);
  assert.equal(mergeActivities([pending], [pending]).length, 0);
});

test('appends YAML without reformatting existing records; no-op is byte identical', () => {
  const original = '# Existing comment\n- title: Existing\n  events: []\n';
  const result = appendActivities(original, [activity()]);
  assert.ok(result.startsWith(original));
  assert.equal(parse(result).length, 2);
  assert.equal(appendActivities(original, []), original);
  assert.equal(parse(appendActivities('[]\n', [activity()])).length, 1);
});

test('query templates follow Shanghai dates and roll into the next year', () => {
  assert.equal(expandQuery('{year}/{month}/{next_year}', new Date('2026-12-31T18:00:00Z')), '2027/01/2028');
});

test('HTTP retries transient errors but not auth errors or leaked response bodies', async () => {
  let calls = 0;
  const response = await postJson('https://example.test', 'secret', {}, async () => {
    calls++;
    return calls === 1 ? { ok: false, status: 429 } : { ok: true, json: async () => ({ ok: true }) };
  }, async () => {});
  assert.deepEqual(response, { ok: true });
  assert.equal(calls, 2);
  calls = 0;
  await assert.rejects(postJson('https://example.test', 'secret', {}, async () => {
    calls++;
    return { ok: false, status: 401 };
  }), /HTTP 401/);
  assert.equal(calls, 1);
});

test('discovery searches configured domains and extracts only real source bodies', async () => {
  const calls = [];
  const request = async (url, key, body) => {
    calls.push({ url, body });
    return url.includes('tavily') ? { results: [source, source, { url: 'https://snippet.test', content: 'Snippet only' }] }
      : extracted([candidate]);
  };
  const result = await discover({ config, base: [], now, env, request });
  assert.equal(calls.length, 2);
  assert.deepEqual(calls[0].body.include_domains, ['mp.weixin.qq.com']);
  assert.equal(result.additions.length, 1);
  assert.equal(result.report.accepted[0].evidence.place, 'Shanghai library');
  assert.equal(result.report.skipped.length, 1);
});

test('repeat discovery keeps the pending PR data and adds no duplicates', async () => {
  const request = async (url) => url.includes('tavily') ? { results: [source] } : extracted([candidate]);
  const result = await discover({ config, base: [], pending: [activity()], now, env, request });
  assert.equal(result.additions.length, 1);
  assert.equal(result.report.accepted.length, 0);
  assert.equal(result.report.retained, 1);
  const merged = await discover({ config, base: [activity()], pending: [activity()], now, env, request });
  assert.equal(merged.additions.length, 0);
});

test('empty search succeeds without calling extraction, while total API failure fails', async () => {
  const result = await discover({ config, base: [], now, env, request: async () => ({ results: [] }) });
  assert.deepEqual(result.additions, []);
  await assert.rejects(discover({ config, base: [], now, env, request: async () => { throw new Error('offline'); } }), /All search queries failed/);
  await assert.rejects(discover({
    config, base: [], now, env,
    request: async (url) => url.includes('tavily') ? { results: [source] } : {},
  }), /All source extractions failed/);
});

test('partial channel failures are reported and do not lose valid results', async () => {
  const result = await discover({
    config: [...config, { channel: 'web', query: 'fail' }], base: [], now, env,
    request: async (url, key, body) => {
      if (body.query === 'fail') throw new Error('HTTP 503');
      return url.includes('tavily') ? { results: [source] } : extracted([candidate]);
    },
  });
  assert.equal(result.additions.length, 1);
  assert.equal(result.report.queries.filter((q) => q.error).length, 1);
});

test('missing credentials and invalid configuration fail before any request', async () => {
  const request = async () => assert.fail('Must not send a request');
  await assert.rejects(discover({ config, base: [], env: {}, request }), /Configure repository secrets/);
  await assert.rejects(discover({ config, base: [], env: { ...env, DISCOVERY_MAX_SOURCES: '0' }, request }), /1 to 50/);
  await assert.rejects(discover({ config, base: [], env: { ...env, OPENAI_BASE_URL: 'http://unsafe.test' }, request }), /HTTPS/);
});

test('existing repository activities can be read and preserved on append', async () => {
  const original = await readFile(new URL('../../../data/activities.yml', import.meta.url), 'utf8');
  const existing = parse(original);
  assert.ok(Array.isArray(existing));
  assert.deepEqual(parse(appendActivities(original, [activity()])).slice(0, existing.length), existing);
});

test('channel selection is round-robin and respects the extraction budget', () => {
  const sources = [
    { channel: 'wechat', url: 'w1' }, { channel: 'wechat', url: 'w2' },
    { channel: 'web', url: 'a1' }, { channel: 'charity', url: 'c1' },
  ];
  assert.deepEqual(selectSources(sources, 3).map((s) => s.url), ['w1', 'a1', 'c1']);
  assert.equal(selectSources(sources, 20).length, 4);
});

test('pending branch does not resurrect historical records deleted from main', async () => {
  const historical = activity();
  const pending = activity();
  pending.title = 'A newly discovered event';
  pending.events[0].id = 'new-event';
  pending.events[0].link = 'https://new.test/event';
  const result = await discover({
    config, base: [], pending: [historical, pending], pendingBase: [historical], now, env,
    request: async () => ({ results: [] }),
  });
  assert.deepEqual(result.additions, [pending]);
});

test('main dry-run writes evidence only; normal run appends once; failure leaves data untouched', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'goodaction-discovery-'));
  const originalEnv = { ...process.env };
  const originalFetch = globalThis.fetch;
  const file = join(dir, 'activities.yml');
  const reportFile = join(dir, 'report.json');
  const future = JSON.parse(JSON.stringify(candidate).replaceAll('2026-', '2099-'));
  const futureSource = { ...source, raw_content: source.raw_content.replaceAll('2026-', '2099-') };
  try {
    for (const key of Object.keys(process.env)) {
      if (/^(DISCOVERY_|PENDING_|OPENAI_|TAVILY_|GITHUB_OUTPUT|GITHUB_STEP_SUMMARY)/.test(key)) delete process.env[key];
    }
    Object.assign(process.env, env, {
      ACTIVITIES_FILE: file, DISCOVERY_REPORT: reportFile, DISCOVERY_DRY_RUN: 'true',
    });
    await writeFile(file, '[]\n');
    globalThis.fetch = async (url) => ({
      ok: true,
      json: async () => url.includes('tavily') ? { results: [futureSource] } : extracted([future]),
    });
    await main();
    assert.equal(await readFile(file, 'utf8'), '[]\n');
    assert.equal(JSON.parse(await readFile(reportFile, 'utf8')).accepted.length, 1);
    process.env.DISCOVERY_DRY_RUN = 'false';
    await main();
    const saved = await readFile(file, 'utf8');
    assert.equal(parse(saved).length, 1);
    await main();
    assert.equal(await readFile(file, 'utf8'), saved);
    delete process.env.OPENAI_API_KEY;
    await assert.rejects(main(), /Configure repository secrets/);
    assert.equal(await readFile(file, 'utf8'), saved);
  } finally {
    globalThis.fetch = originalFetch;
    for (const key of Object.keys(process.env)) {
      if (!(key in originalEnv)) delete process.env[key];
    }
    Object.assign(process.env, originalEnv);
    await rm(dir, { recursive: true, force: true });
  }
});

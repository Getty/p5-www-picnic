# WWW::Picnic House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Library to access the Picnic Supermarket API. Read first: the caller in `WWW::Picnic`, the
matching `WWW::Picnic::Result::*` class, and the `MockUA` sample generator for that endpoint.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `www-picnic-worker` (default) |
| Write/extend tests | `www-picnic-test-writer` |
| Write/maintain POD | `www-picnic-doc-writer` |
| Commits, `Changes`, card → done, pre-release audit | `www-picnic-release-manager` |
| Read-only research, audit, gap analysis | `www-picnic-worker` ("read-only, change nothing") |

Behavior-relevant = runtime behavior, the public API (`WWW::Picnic`, `::Result::*`), auth and
2FA flow, search/cart/article endpoints, CLI commands, error handling, tests, performance. Pure
prose docs and `Changes` notes are not.

## Deviations from the house rules

The public tracker here is CPAN RT — the publish gate's tracker rule applies to RT tickets:
never list, view, comment on, edit, close or create one unless the user names the ticket.

## Hazards

- **Live API test hits a real account.** `t/basic.t` runs only when `TEST_WWW_PICNIC_USER` +
  `TEST_WWW_PICNIC_PASS` are set; never set those env vars in a fanned-out or parallel
  context. The test mutates state (it can call `clear_cart` and login flows) and would touch
  the real Picnic account of whoever's credentials are present.
- **Auth token lives on the instance.** `_auth_cache` is `ro` with a default `sub {{}}` —
  there is exactly one auth token per `WWW::Picnic` object. Reusing an instance across threads
  is unsafe; one client per logical session.
- **Search endpoint shape changed.** The live API returns a nested
  `body.child.children[].child.children[].sellingUnit` shape; do not "simplify" the parser in
  `WWW::Picnic::Result::Search` without re-checking against a real response and updating the
  `sample_search_response` fixture.
- **2FA is interactive.** `verify_2fa_code($sms_code)` is the only way past a `requires_2fa`
  login; the CLI prompts on `<STDIN>`. Anything scripted against a 2FA account must surface
  that prompt or the user will hang silently.
- **Test runner trap.** Plain `prove -l t/` is non-recursive; always use `prove -lr t` so any
  future subdir tests are never silently skipped (the suite is flat today, keep `-r` anyway).

## Perl specifics — reference, don't restate

Module loading, Moo patterns, dependency pinning, `[@Author::GETTY]` release metadata, POD
directives and house style live in skills `getty-perl-core`, `getty-perl-moo`,
`perl-release-dist-ini`, `getty-perl-release-author-getty` and `www-picnic-perl`
(force-loaded for `www-picnic-*` agents).

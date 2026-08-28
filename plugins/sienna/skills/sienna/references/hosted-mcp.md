# Hosted MCP 사용 계약

이 문서는 Sienna 앱이 제공하는 Hosted AI 연결의 공개 입력과 출력을 설명한다.
로컬 Plugin 작업에는 CLI를 사용하고, Hosted 연결에는 아래 도구만 사용한다. 모든
`job_id`는 UUID이며 UI·CLI·MCP에서 같은 Job을 가리킨다.

## 연결과 도구

- URL: `https://mcp.sienna.work/mcp`
- 읽기 권한: `sienna.analytics.read`, `sienna.jobs.read`, 필요한 경우
  `sienna.creative.read`
- lifecycle 변경 권한: `sienna.jobs.write`
- action: `ads_accounts`, `ads_metrics`, `ads_creatives`, `research`
- Listen 읽기: `listen_posts`, `listen_search`, `listen_stats`,
  `listen_target_list`, `listen_target_show`
- Listen monitoring target 변경: `listen_target_preflight`,
  `listen_target_register`, `listen_target_pause`, `listen_target_resume`,
  `listen_target_delete` — `sienna.jobs.write` 권한이 필요하다.
- watchlist 읽기: `watchlist_preflight`, `watchlist_list`, `watchlist_show`,
  `watchlist_runs` — 읽기 권한 `sienna.analytics.read`로 게이팅된다.
- watchlist 변경: `watchlist_add`, `watchlist_pause`, `watchlist_resume`,
  `watchlist_delete` — Job lifecycle과 같은 `sienna.jobs.write` 권한이 필요하다.
- lifecycle: `job_list`, `job_status`, `job_answer`, `job_cancel`, `job_delete`,
  `job_restore`, `job_purge`

Hosted MCP에는 범용 `ask`, 범용 `read`, `job_continue`, `wait`, retry 도구가 없다.
게시·수정·provider 연결 및 해제도 지원하지 않는다.

## Action 선택

| 도구 | 공개 계약 |
| --- | --- |
| `ads_accounts` | `operation=list|ask`. `platforms` 생략은 Meta·Google·Adjust 전체, 지정은 필터다. `ask`에는 `prompt`가 필수다. |
| `ads_metrics` | `operation=query|ask`. `query`는 단일 `platform`과 일치하는 provider-native `arguments`가 필수다. `ask`에는 `prompt`가 필수이며 `platforms`와 선택적 account를 받을 수 있다. |
| `ads_creatives` | `operation=list|show|search`와 그 operation에 맞는 strict `arguments`를 사용한다. 결과는 bounded이며 소유 계정만 조회한다. |
| `research` | `prompt`가 필수다. `scope`는 optional `market|brand|competitor` 배열, `depth`는 optional `quick|standard`다. scope 생략은 자동 선택이다. |

모든 action 호출에는 caller가 만든 UUID `idempotency_key`가 필수다. 응답이
끊기거나 timeout이 발생한 동일 요청 재전송에는 같은 key를 재사용한다. 같은 key로
다른 입력을 보내면 conflict다. Action은 즉시 같은 `job_id`의 acknowledgement를
반환할 수 있으므로 결과가 없다고 실패로 판단하지 않는다.

Ads·Creative·Research 결과의 `data.web_url`은 사용자가 Sienna에서 실제 광고
preview를 확인할 수 있는 인증된 경로다. 반환된 URL을 그대로 제시하고 같은 Sienna
계정 로그인이 필요할 수 있음을 안내한다. Job ID나 provider field로 URL을 조립하거나
`web_url`을 접근 권한으로 설명하지 않는다.

구조화 입력이 잘못됐거나 계정이 확정되지 않으면 명시적 validation 오류다. 자연어
요청에서 사용자의 판단이 필요하면 Job이 `needs_input`이 된다. 질문과 bounded
choices를 그대로 보여주고 사용자가 답한 후 `job_answer`를 호출한다.

## Listen

Listen은 현재 active organization이 소유하는 keyword/community monitoring
target과 수집 결과를 조회·관리한다. 기존 Watchlist는 사용자가 소유하는 URL/research
도메인이므로 두 리소스를 서로 대체하거나 같은 것으로 해석하지 않는다.

organization, upstream URL, provider 또는 collector는 도구 입력으로 받지 않는다.
서버는 매 호출 시 현재 active organization과 membership을 다시 확인한다. organization이
바뀌거나 membership이 철회되었거나 active organization이 더 이상 유효하지 않으면
기존 결과나 preview를 우회해 사용하지 말고 새 상태에서 다시 시작한다.

- `listen_posts`, `listen_search`, `listen_stats`는 현재 organization의 bounded 수집
  결과를 읽는다.
- `listen_target_preflight`는 keyword/community 후보를 검증하고 등록 가능한
  `preflight_token`을 반환한다.
- `listen_target_register`, `listen_target_pause`, `listen_target_resume`,
  `listen_target_delete`는 `execute=false`, `confirmed=false`로 먼저 preview한다.
  사용자의 명시적 확인 후 같은 UUID `idempotency_key`를 사용해 `execute=true`,
  `confirmed=true`로 실행한다. pause/resume/delete는 preview가 반환한 최신
  `expected_revision`도 전달한다.
- organization member는 register/pause/resume을 실행할 수 있다. delete 실행은
  owner만 가능하며 되돌릴 수 없다.

`forbidden`이면 membership·역할·active organization을 새로 확인한다.
`revision_conflict`이면 target을 다시 조회하고 새 preview와 사용자 확인을 받는다.
`invalid_preflight`이면 preflight부터 다시 수행한다. `idempotency_conflict`이면 같은
key에 다른 입력을 재사용하지 말고, 사용자가 확인한 새 작업에 새 UUID를 만든다.

## Watchlist

Watchlist 도구는 즉시 결과를 반환하며 Job을 만들지 않는다. 지원 URL은 경쟁사
웹사이트, Google Ads Transparency, Meta Ad Library다(Meta는 source gate 승인
후에만). `watchlist_preflight`로 후보를 먼저 확인한다. `watchlist_add`,
`watchlist_pause`, `watchlist_resume`, `watchlist_delete`는 `execute=false`
(기본값)로 미리보기만 하며, 사용자의 명시적 확인 후에만 `execute=true`로
재호출한다 — Job lifecycle의 `dry_run`과 이름은 다르지만 같은
preview-then-confirm 구조다. `watchlist_delete`는 destructive로 표시된다.

`watchlist_show`에 `current_results=true`를 주면 저장된 최신 광고 inventory와
creative 분석 결과를 새 수집 없이 함께 반환한다. `observed_at`,
`exact|at_least`, `cap_hit`, coverage gap을 보존한다. `watchlist_runs`는 실행
상태·요약 목록이며 generation 간 diff나 변경 이력이 아니다.

### Watchlist 오류 복구

- `invalid_watchlist_url`: 지원되는 `https://` 경쟁사 웹사이트, Google Ads
  Transparency, Meta Ad Library URL을 제공하고 `watchlist_preflight`을 다시
  호출한다.
- `watchlist_not_found`, `watchlist_deleted`: `watchlist_list`로 상태를
  새로고침한 뒤 재시도한다.
- `watchlist_preflight_expired`, `watchlist_preflight_not_registrable`:
  `watchlist_preflight`을 다시 호출해 새 `preflight_id`/`candidate_token`을
  받는다.
- `watchlist_quota_exceeded`: 다른 Watchlist를 `watchlist_pause` 또는
  `watchlist_delete`로 정리한 뒤 재시도한다.
- `watchlist_source_unavailable`, `watchlist_storage_unavailable`: 잠시 후
  재시도한다. 인증 실패로 재해석하지 않는다.

## Job lifecycle

- `job_list`: UI·CLI·MCP에서 생성된 읽을 수 있는 Job을 최신순으로 반환한다.
  `trashed=true`는 휴지통만 조회한다.
- `job_status`: 일반 진행 단계 `preparing|retrieving|finalizing`, target 상태,
  `needs_input`, terminal 결과와 `poll_after_ms`를 반환한다.
- `job_answer`: `needs_input`에만 사용하며 새 실행 generation을 시작한다.
- `job_cancel|delete|restore|purge`: `dry_run=true`로 먼저 확인하고 사용자의 명시적
  확인 후 `dry_run=false`로 실행한다.

`job_status`의 `poll_after_ms` 이후에만 다시 조회한다. `pending|running` target은 아직
결과가 아니며, terminal target은 `succeeded|partial|failed|skipped`다. 일부 target이
실패해도 성공 target 결과와 실패 target의 recovery를 보존하고 전체 `partial`을 그대로 설명한다. Terminal
partial을 이어가는 공개 continuation은 없다.

Active 또는 `needs_input` Job은 먼저 cancel한 뒤 delete한다. Delete는 30일 휴지통으로
이동하고, restore는 만료 전 복구하며, purge는 휴지통의 개별 Job을 영구 삭제한다.
Job 기록은 삭제 전까지 유지되지만 실행 상태와 입력 대기는 24시간 후 만료된다.

목록·상태·answer는 현재 data scope를 다시 검증한다. 권한이 철회되면 결과를 우회해서
요청하지 않는다. 취소·삭제·복원·purge는 소유권과 write scope를 검증하며 결과 본문을
노출하지 않는다.

## 결과 해석과 안전

- 성공 envelope, 오류 `kind`, `message`, `retryable`, `retry_after_ms`, `recovery`를
  보존한다.
- 광고 Ask의 `schema_version=ask-result-v1`은 `results`, target별 `errors`,
  `warnings`, `timing`을 반환한다. 각 result의 account, 요청·확정 scope,
  provider-native field·unit, rows와 collection limit를 보존한다. 빈 rows도 성공이다.
  해석을 요청한 Ask는 `answer_contract_version=ask-answer-v1`과 선택적 `answer`를
  함께 반환할 수 있다. 존재하는 요약, 근거 관찰과 추천만 구조화 결과 앞에 보여주고
  없는 분석 section을 만들어내지 않는다.
  답변 문자열은 문단, 2·3단계 제목, 목록, 강조, 인라인 코드, HTTPS 링크와 GFM 표를
  사용할 수 있다. 유용한 형식은 보존하며 표는 각각 최대 10열과 50개 데이터 행이다.
  raw HTML, 이미지, embed, script, style, fenced code 또는 HTTPS가 아닌 링크를
  활성화하지 않는다.
  수집 한계가 있으면 사용자에게 보여주고 추가 조회 여부는 사용자가 판단하게 한다.
  Evidence, citation 또는 coverage 점수를 데이터 표시 조건으로 요구하지 않는다.
  기존 저장 Job의 answer 형태 result도 그대로 읽는다.
- Research의 market·brand·competitor 결과, coverage, gaps와 scope별 outcome을
  구분한다. 공개 광고 존재나 기간을 성과 지표로 해석하지 않는다.
- Provider 원문이 unavailable이어도 bounded Job 결과를 폐기하지 않는다.
- credential, 사용자 identity, upstream host, full URL, HTTP method를 입력하거나
  표시하지 않는다.

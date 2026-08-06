# Hosted MCP 사용 계약

이 문서는 Sienna 앱에서 제공되는 Hosted AI 연결의 입력과 출력을 설명한다.
로컬 Plugin 작업에는 Sienna CLI를 사용하고, Hosted 연결에는 아래 도구만 사용한다.
로컬 CLI의 request ID와 Hosted `job_ref`를 서로 바꾸어 사용하지 않는다.

## 연결 입력

- URL: `https://mcp.sienna.work/mcp`
- OAuth 권한: `sienna.analytics.read`, `sienna.jobs.read`,
  `sienna.creative.read`
- 취소 권한: `sienna.jobs.write`가 추가로 필요할 수 있다.
- 도구: `sienna_ask`, `sienna_job_status`, `sienna_job_continue`,
  `sienna_job_cancel`, `sienna_read`

Sienna 앱이 현재 제공하는 호스트 연결만 안내한다. 연결 화면에 없는 호스트나
설치 경로를 공개 지원이라고 주장하지 않는다.

## 요청과 결과

`sienna_ask`는 완전한 질문과 optional `crew`를 받는다. Research 요청에는 optional
`research_depth=quick|standard|deep`를 추가할 수 있으며 생략값은 `standard`다.
`crew`는 `performance`, `measurement`, `creative`, `research` 중 하나다.
`strategy`는 사용할 수 없다.

성공 결과는 `{ok:true,data:{...}}` 형태다. 오류 결과의 `kind`, `retryable`,
`retry_after_ms`, `message`, `recovery`를 보존하고, `insufficient_scope`가 반환되면
요청된 추가 권한을 사용자에게 설명한다. provider 원문이나 credential을 요청하거나
표시하지 않는다.

모든 completed 또는 partial Ask 결과에는 `schema_version=ask-answer-v1`,
일치하는 status, 근거가 연결된 claim/action, crew, answer policy provenance를
갖는 사용자용 `answer`가 포함된다. 일반 결과에는 raw evidence와
`requested_crew`, `resolved_crew`, `routing_source`, `catalog_version`가 추가로
포함될 수 있다. answer가 없거나 형식이 잘못됐거나 반환된 근거와 연결되지 않으면
evidence가 있어도 실패 결과로 취급한다. status·continue·cancel에는 최초 결과가
반환한 exact `job_ref`를 사용하며 crew나 depth를 다시 보내지 않는다.

완료된 Research 결과는 grounded `answer`와 exact 또는 lower-bound total, 광고주별 inventory,
count completeness, coverage scope, 대표 광고를 포함할 수 있다. Quick 결과의
`totals.count_relation=at_least`를 exact로 표현하지 않는다. 미확정 후보가 있으면
`identity_coverage.complete=false`, `totals.count_complete=false`, coverage warning을
그대로 보존한다. identity 오류는 반환된 `kind`, `stage=identity_resolution`,
`reason`, `identity_coverage`, `evidence_impact`, `recovery`로 보고한다.
`creative_center_top_ads`를 전체 TikTok 광고나 성과 데이터로 해석하지 않는다.

`sienna_job_cancel`은 변경 작업이므로 먼저 `dry_run=true`로 대상을 확인하고 사용자의
명시적 확인 후 실행한다. status, continue, cancel은 job을 만든 동일한 Hosted 연결에서
실행한다. 연결 불일치가 반환되면 job을 만든 원래 Hosted 연결을 복구하고 동일한
`job_ref`로 lifecycle 명령을 다시 실행한다. 새 Ask로 status, continue, cancel을
대체하지 않는다. 원래 연결을 복구할 수 없으면 취소가 실패했으며 job이 계속 실행될
수 있음을 사용자에게 알린다.

## 지원하지 않는 작업

- Hosted MCP에는 `sienna_job_answer`가 없다. Hosted Ask가 `needs_input`을 반환하면
  답을 추측하거나 해당 `job_ref`를 CLI에서 재사용하지 않는다. 같은 질문을 로컬
  `sienna ask query`로 새로 시작하고, 반환된 질문과 exact `answer_command`를 사용한다.
- Hosted MCP에는 Rooms와 history 도구가 없다. Rooms, Ask history, provider history가
  필요하면 로컬 CLI의 해당 명령을 사용한다.
- 게시, 수정, 삭제, provider 연결·해제는 지원하지 않는다. 지원하지 않는 요청을
  다른 도구로 우회하지 않는다.

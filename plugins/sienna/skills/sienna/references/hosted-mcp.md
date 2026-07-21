# Hosted MCP와 로컬 Plugin 경계

이 Skill은 Claude Cowork·Claude Code의 로컬 Plugin/CLI 실행 surface다. Hosted AI 연결은
Sienna 앱에서 별도로 관리하며 로컬 CLI session이나 provider credential을 호스트에
전달하지 않는다.

- 프로덕션 remote URL: `https://mcp.sienna.work/mcp`
- OAuth issuer: `https://auth.sienna.work`
- 읽기 scope: `sienna.analytics.read`, `sienna.jobs.read`, `sienna.creative.read`
- 도구: `sienna_ask`, `sienna_job_status`, `sienna_job_continue`, `sienna_read`

remote endpoint는 완전 stateless Streamable HTTP이므로 임의 session ID를 만들거나
재사용하지 않는다. 지원 protocol version은 `2025-11-25`, `2025-06-18`,
`2025-03-26`이며 더 새로운 날짜를 요청하면 최신 지원 버전으로 협상한다. 성공한 도구
결과는 `{ok:true,data:{...}}` envelope를 사용한다. 잘못된 tool arguments는 JSON-RPC
`-32602`, 인증·transport 이외의 실행 실패는 HTTP 200의 `isError` tool result로 받는다.
provider 조회는 analytics scope, creative 조회는 creative scope만 요구하며 오류는 provider
원문 없이 안정적인 `kind`, `retryable`, 필요 시 `retry_after_ms`로 반환한다.
`insufficient_scope`는 JSON-RPC `isError` 본문을 유지하면서 정확한 필요 scope와 protected
resource metadata URL이 든 RFC 6750 Bearer challenge를 함께 반환하므로 호스트가 단계적
OAuth 재동의를 시작할 수 있다.

`sienna_ask`는 CLI와 같은 optional top-level `crew`를 받는다. 생략하면 서버 auto
router가 `performance`·`measurement`·`creative` 중 선택하고, 명시하면 해당 root
profile로 고정한다. `strategy`는 비활성이다. crew는 하나의 Query Agent 안의 실행
profile이지 Hosted host의 multi-agent/subagent 기능이 아니다. 결과와
`sienna_job_status`·`sienna_job_continue`는 raw evidence와 동일한 typed
`requested_crew`·`resolved_crew`·`routing_source`·`catalog_version` provenance를
전달하며, continue에는 crew를 다시 보내지 않는다.

Hosted MCP에는 `sienna_job_answer`가 없다. Hosted Ask가 `needs_input`을 반환하면 해당
Hosted job을 CLI request id로 교차 재개하거나 답을 추정하지 않는다. 같은 질문을 로컬
CLI에서 새로 `sienna ask query`한 뒤, 반환된 질문을 사용자에게 확인하고 정확한
`sienna ask answer <request_id> "<answer>" --json` 명령으로만 재개한다.

Hosted MCP는 skills나 agents 파일을 HTTP로 서빙하지 않는다. 호스트의 설치형 package는
자체 Skill을 포함하고 remote MCP URL만 참조한다. Notion Custom Agent는 Plugin package를
설치하지 않고 승인된 workspace에서 Agent별 Custom MCP 연결을 만든다.

Hosted 도구는 전부 읽기 전용이다. 게시, 수정, 삭제, provider 연결·해제는 등록하지 않으며
자연어 입력에 포함돼도 거부한다. Hosted job은 `mcp` 경로에서만 상태 확인·재개할 수 있고
로컬 `sienna ask wait`/`continue`와 교차 재개하지 않는다. 상태 확인과 재개는 job을 만든
동일한 활성 connection ID에서만 가능하다. Sienna 앱은 같은 호스트의 연결 generation을
각각 표시하고 활성·재인증 필요 연결을 개별 철회한다. 한 Hosted 연결을 끊어도 로컬 CLI
login은 유지된다.

Claude는 Sienna 앱의 Connect 또는 수동 custom connector 절차를 사용한다. ChatGPT는
공개 Plugin 승인이 끝나기 전 일반 사용자 CTA를 제공하지 않는다. Notion은
Business/Enterprise, 관리자 허용, Sienna pilot allowlist와 승인된 connector 사용자가
모두 충족된 경우만 주간 리포트 용도로 Agent별 연결한다. 앱의 Notion CTA는 현재 사용자의
파일럿 eligibility가 실제로 충족된 경우에만 표시한다.

package constrained_shortest_path

import "core:c"

INF :: i64(9223372036854775807)
MAX_NODES :: 16
MAX_EDGES :: 64
MAX_RESOURCE :: 32

@(export)
constrained_shortest_path :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil do return -2
    if length < 5 do return -2
    n_raw := input[0]
    m_raw := input[1]
    start_raw := input[2]
    target_raw := input[3]
    limit_raw := input[4]
    if n_raw < 1 || n_raw > MAX_NODES || m_raw < 0 || m_raw > MAX_EDGES || limit_raw < 0 || limit_raw > MAX_RESOURCE do return -2
    n := int(n_raw)
    m := int(m_raw)
    limit := int(limit_raw)
    if length != c.size_t(5+4*m) || start_raw < 0 || start_raw >= n_raw || target_raw < 0 || target_raw >= n_raw do return -2
    for e:=0; e<m; e+=1 {
        p := 5+4*e
        if input[p] < 0 || input[p] >= n_raw || input[p+1] < 0 || input[p+1] >= n_raw || input[p+2] < 0 || input[p+2] > 1000 || input[p+3] < 1 || input[p+3] > MAX_RESOURCE do return -2
    }
    dp: [33][16]i64
    for r:=0; r<=limit; r+=1 { for u:=0; u<n; u+=1 { dp[r][u]=INF } }
    start := int(start_raw)
    target := int(target_raw)
    dp[0][start]=0
    for r:=0; r<=limit; r+=1 {
        for u:=0; u<n; u+=1 {
            if dp[r][u] == INF do continue
            for e:=0; e<m; e+=1 {
                p:=5+4*e
                if input[p] != i64(u) do continue
                resource:=int(input[p+3])
                if r+resource<=limit {
                    v:=int(input[p+1])
                    candidate:=dp[r][u]+input[p+2]
                    if candidate<dp[r+resource][v] do dp[r+resource][v]=candidate
                }
            }
        }
    }
    answer:=INF
    for r:=0; r<=limit; r+=1 { if dp[r][target]<answer do answer=dp[r][target] }
    if answer==INF do return -1
    return answer
}

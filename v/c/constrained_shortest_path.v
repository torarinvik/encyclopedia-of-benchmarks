module constrained_shortest_path

const max_nodes = 16
const max_edges = 64
const max_resource = 32

@[export: 'constrained_shortest_path']
pub fn constrained_shortest_path(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 5 { return -2 }
    unsafe {
        n_raw := input[0]
        m_raw := input[1]
        start_raw := input[2]
        target_raw := input[3]
        limit_raw := input[4]
        if n_raw < 1 || n_raw > max_nodes || m_raw < 0 || m_raw > max_edges || limit_raw < 0 || limit_raw > max_resource { return -2 }
        n := int(n_raw)
        m := int(m_raw)
        limit := int(limit_raw)
        if length != usize(5+4*m) || start_raw < 0 || start_raw >= n_raw || target_raw < 0 || target_raw >= n_raw { return -2 }
        for e in 0 .. m {
            p := 5+4*e
            if input[p] < 0 || input[p] >= n_raw || input[p+1] < 0 || input[p+1] >= n_raw || input[p+2] < 0 || input[p+2] > 1000 || input[p+3] < 1 || input[p+3] > max_resource { return -2 }
        }
        if start_raw == target_raw { return 0 }
        // At most 32 positive-resource edges can fit, each with cost at most 1000.
        inf := i64(1000000)
        mut dp := [528]i64{}
        for r in 0 .. (limit + 1) { for u in 0 .. n { dp[r * 16 + u] = inf } }
        dp[int(start_raw)] = 0
        for r in 0 .. (limit + 1) {
            for u in 0 .. n {
                current := dp[r * 16 + u]
                if current == inf { continue }
                for e in 0 .. m {
                    p := 5+4*e
                    if input[p] != i64(u) { continue }
                    resource := int(input[p+3])
                    if r+resource <= limit {
                        v := int(input[p+1])
                        candidate := current + input[p+2]
                        at := (r + resource) * 16 + v
                        if candidate < dp[at] { dp[at] = candidate }
                    }
                }
            }
        }
        mut answer := inf
        for r in 0 .. (limit + 1) { if dp[r * 16 + int(target_raw)] < answer { answer = dp[r * 16 + int(target_raw)] } }
        if answer == inf { return -1 }
        return answer
    }
}

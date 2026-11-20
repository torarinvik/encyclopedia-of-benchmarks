// Independently authored bounded subset-assignment draft; unverified.
@[export: 'tree_sibling_distinct_cost_coloring']
pub fn tree_sibling_distinct_cost_coloring(input &i64, length usize) i64 {
    if length < 3 || length > 354 { return -1 }
    unsafe {
        if input == nil { return -1 }
        if input[0] < 1 || input[0] > 32 || input[1] < 1 || input[1] > 10 { return -1 }
        n, k := int(input[0]), int(input[1])
        if length != usize(n+1+n*k) { return -1 }
        for vertex in 1 .. n {
            if input[1+vertex] < 0 || input[1+vertex] >= i64(vertex) { return -1 }
        }
        for i in 0 .. n*k {
            if input[n+1+i] < 0 || input[n+1+i] > 1000000 { return -1 }
        }
        inf := i64(1000000000000)
        states := 1 << k
        mut dp := [320]i64{}
        mut current := [1024]i64{}
        mut next := [1024]i64{}
        mut vertex := n
        for vertex > 0 {
            vertex--
            for color in 0 .. k {
                for mask in 0 .. states { current[mask] = inf }
                current[1 << color] = 0
                for child in vertex+1 .. n {
                    if input[1+child] != i64(vertex) { continue }
                    for mask in 0 .. states { next[mask] = inf }
                    for mask in 0 .. states {
                        if current[mask] == inf { continue }
                        for c in 0 .. k {
                            bit := 1 << c
                            if (mask & bit) != 0 || dp[10*child+c] == inf { continue }
                            target := mask | bit
                            candidate := current[mask]+dp[10*child+c]
                            if candidate < next[target] { next[target] = candidate }
                        }
                    }
                    for mask in 0 .. states { current[mask] = next[mask] }
                }
                mut best := inf
                for mask in 0 .. states { if current[mask] < best { best = current[mask] } }
                dp[10*vertex+color] = if best == inf { inf } else { best+input[n+1+vertex*k+color] }
            }
        }
        mut best := inf
        for color in 0 .. k { if dp[color] < best { best = dp[color] } }
        return if best == inf { -2 } else { best }
    }
}

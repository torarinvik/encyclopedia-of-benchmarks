package problem136

@(export)
problem136 :: proc "c" (n_limit: i64) -> i64 {
    if n_limit > 100000 do return -1
    if n_limit <= 0 do return 0
    solutions: [100000]u8
    max_delta := (n_limit + 1) / 4
    for delta := i64(1); delta <= max_delta; delta += 1 {
        for y := 4 * delta - 1; y > delta; y -= 1 {
            n := y * (4 * delta - y)
            if n >= n_limit do break
            if solutions[int(n)] < 2 { solutions[int(n)] += 1 }
        }
    }
    answer := i64(0)
    for n := i64(0); n < n_limit; n += 1 { if solutions[int(n)] == 1 { answer += 1 } }
    return answer
}

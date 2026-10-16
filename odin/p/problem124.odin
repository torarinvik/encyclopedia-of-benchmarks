package problem124

@(export)
problem124 :: proc "c" (n_max, k: i64) -> i64 {
    if n_max < 1 || n_max > 100000 || k < 1 || k > n_max do return -1
    n := int(n_max)
    radicals: [100001]i64
    counts: [100001]i64
    for i := 1; i <= n; i += 1 { radicals[i] = 1 }
    for p := 2; p <= n; p += 1 {
        if radicals[p] == 1 {
            for multiple := p; multiple <= n; multiple += p { radicals[multiple] *= i64(p) }
        }
    }
    for i := 1; i <= n; i += 1 { counts[radicals[i]] += 1 }
    remaining := k
    for rad := 1; rad <= n; rad += 1 {
        if remaining > counts[rad] { remaining -= counts[rad]; continue }
        for value := 1; value <= n; value += 1 {
            if radicals[value] == i64(rad) {
                remaining -= 1
                if remaining == 0 do return i64(value)
            }
        }
    }
    return -1
}

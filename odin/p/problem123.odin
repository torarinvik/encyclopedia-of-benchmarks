// Find the first odd prime index whose source remainder exceeds the limit.
package problem123

MAX_LIMIT :: i64(10_000_000_000)
PRIME_LIMIT :: 300_000

@(export)
problem123 :: proc "c" (limit: i64) -> i64 {
    if limit > MAX_LIMIT do return -1
    composite: [PRIME_LIMIT + 1]bool = {}
    for factor := 2; factor * factor <= PRIME_LIMIT; factor += 1 {
        if !composite[factor] {
            for multiple := factor * factor; multiple <= PRIME_LIMIT; multiple += factor {
                composite[multiple] = true
            }
        }
    }
    n := i64(1)
    skip_next := false
    for candidate := 2; candidate <= PRIME_LIMIT; candidate += 1 {
        if composite[candidate] do continue
        if skip_next { skip_next = false; continue }
        if 2 * i64(candidate) * n > limit do return n
        skip_next = true
        n += 2
    }
    return -1
}

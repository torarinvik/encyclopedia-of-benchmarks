// Find the first odd prime index whose source remainder exceeds the limit.
module problem123

const max_limit = i64(10000000000)
const prime_limit = 300000

@[export: 'problem123']
pub fn problem123(limit i64) i64 {
    if limit > max_limit { return -1 }
    mut composite := [prime_limit + 1]bool{}
    mut factor := 2
    for factor * factor <= prime_limit {
        if !composite[factor] {
            mut multiple := factor * factor
            for multiple <= prime_limit {
                composite[multiple] = true
                multiple += factor
            }
        }
        factor++
    }
    mut n := i64(1)
    mut skip_next := false
    for candidate := 2; candidate <= prime_limit; candidate++ {
        if composite[candidate] { continue }
        if skip_next {
            skip_next = false
            continue
        }
        if 2 * i64(candidate) * n > limit { return n }
        skip_next = true
        n += 2
    }
    return -1
}

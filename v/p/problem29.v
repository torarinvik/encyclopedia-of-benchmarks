// Count distinct powers using maximal perfect-power roots.
module problem29

@[export: 'problem29']
pub fn problem29(limit i64) i64 {
    if limit < 1 || limit > 100 { return -1 }
    if limit == 1 { return 0 }
    mut roots := [101]i64{}
    mut exponents := [101]i64{}
    mut seen := [60701]bool{}
    mut distinct := i64(0)
    for a in 2 .. int(limit + 1) {
        roots[a] = i64(a)
        exponents[a] = 1
        for candidate_exponent in 2 .. 7 {
            for candidate_root in 2 .. a + 1 {
                mut power := i64(1)
                for _ in 0 .. candidate_exponent {
                    power *= i64(candidate_root)
                    if power > i64(a) { break }
                }
                if power == i64(a) && i64(candidate_exponent) > exponents[a] {
                    roots[a] = i64(candidate_root)
                    exponents[a] = i64(candidate_exponent)
                }
            }
        }
        for b in 2 .. int(limit + 1) {
            key := int(roots[a] * 601 + exponents[a] * i64(b))
            if !seen[key] { seen[key] = true; distinct++ }
        }
    }
    return distinct
}

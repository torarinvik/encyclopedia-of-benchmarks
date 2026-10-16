package problem29

@(export)
problem29 :: proc "c" (limit: i64) -> i64 {
    if limit < 1 || limit > 100 do return -1
    if limit == 1 do return 0
    roots: [101]i64
    exponents: [101]i64
    seen: [60701]bool
    distinct := i64(0)
    for a := i64(2); a <= limit; a += 1 {
        roots[a] = a
        exponents[a] = 1
        for candidate_exponent := i64(2); candidate_exponent <= 6; candidate_exponent += 1 {
            for candidate_root := i64(2); candidate_root <= a; candidate_root += 1 {
                power := i64(1)
                for step := i64(0); step < candidate_exponent; step += 1 {
                    power *= candidate_root
                    if power > a do break
                }
                if power == a && candidate_exponent > exponents[a] {
                    roots[a] = candidate_root
                    exponents[a] = candidate_exponent
                }
            }
        }
        for b := i64(2); b <= limit; b += 1 {
            key := int(roots[a] * 601 + exponents[a] * b)
            if !seen[key] { seen[key] = true; distinct += 1 }
        }
    }
    return distinct
}

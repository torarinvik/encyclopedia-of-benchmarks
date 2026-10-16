// Search odd divisors for the first source repunit length exceeding limit.
package problem129

MAX_LIMIT :: i64(1_000_000)

least_divisible_repunit :: proc(divisor: i64) -> i64 {
    if divisor % 5 == 0 || divisor % 2 == 0 do return 0
    repunit := i64(1)
    repunit_index := i64(1)
    for repunit != 0 {
        repunit = (10 * repunit + 1) % divisor
        repunit_index += 1
    }
    return repunit_index
}

@(export)
problem129 :: proc "c" (limit: i64) -> i64 {
    if limit < 1 || limit > MAX_LIMIT do return -1
    divisor := limit - 1
    if divisor % 2 == 0 { divisor += 1 }
    for least_divisible_repunit(divisor) <= limit { divisor += 2 }
    return divisor
}

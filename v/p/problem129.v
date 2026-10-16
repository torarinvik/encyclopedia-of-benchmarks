// Search odd divisors for the first source repunit length exceeding limit.
module problem129

const max_limit = i64(1000000)

fn least_divisible_repunit(divisor i64) i64 {
    if divisor % 5 == 0 || divisor % 2 == 0 { return 0 }
    mut repunit := i64(1)
    mut repunit_index := i64(1)
    for repunit != 0 {
        repunit = (10 * repunit + 1) % divisor
        repunit_index++
    }
    return repunit_index
}

@[export: 'problem129']
pub fn problem129(limit i64) i64 {
    if limit < 1 || limit > max_limit { return -1 }
    mut divisor := limit - 1
    if divisor % 2 == 0 { divisor++ }
    for least_divisible_repunit(divisor) <= limit { divisor += 2 }
    return divisor
}

/// Search odd divisors for the first source repunit length exceeding limit.
const MAX_LIMIT: i64 = 1_000_000;

fn leastDivisibleRepunit(divisor: i64) i64 {
    if (@mod(divisor, 5) == 0 or @mod(divisor, 2) == 0) return 0;
    var repunit: i64 = 1;
    var repunit_index: i64 = 1;
    while (repunit != 0) {
        repunit = @mod(10 * repunit + 1, divisor);
        repunit_index += 1;
    }
    return repunit_index;
}

export fn problem129(limit: i64) i64 {
    if (limit < 1 or limit > MAX_LIMIT) return -1;
    var divisor = limit - 1;
    if (@mod(divisor, 2) == 0) divisor += 1;
    while (leastDivisibleRepunit(divisor) <= limit) divisor += 2;
    return divisor;
}

const MAX_N: i64 = 10;
const SEARCH_MAX: i64 = 64;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn isPrimeTrial(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

fn fortunateTerm(n: i64) i64 {
    var primorial: i64 = 1;
    var primes_found: i64 = 0;
    var candidate: i64 = 2;
    while (primes_found < n) : (candidate += 1) {
        if (isPrimeTrial(candidate)) {
            primorial *= candidate;
            primes_found += 1;
        }
    }
    var offset: i64 = 2;
    while (offset <= SEARCH_MAX) : (offset += 1) {
        if (isPrimeTrial(primorial + offset)) return offset;
    }
    return -2;
}

export fn fortunate_numbers(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1) return -1;
    const n = values[0];
    if (n < 1 or n > MAX_N) return -1;
    return fortunateTerm(n);
}

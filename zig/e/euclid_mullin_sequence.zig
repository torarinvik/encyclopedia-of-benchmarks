const MAX_PARSEABLE_LENGTH: usize = 2;
const MAX_N: i64 = 8;

fn leastPrimeFactor(value: i64) i64 {
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@mod(value, divisor) == 0) return divisor;
    }
    return value;
}

fn euclidMullinTerm(index: i64) i64 {
    var product: i64 = 1;
    var term: i64 = 1;
    for (0..@intCast(index)) |_| {
        term = leastPrimeFactor(product + 1);
        product *= term;
    }
    return term;
}

export fn euclid_mullin_sequence(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = input_opt.?[0..length];
    if (length != 1 or input[0] < 1 or input[0] > MAX_N) return -1;
    return euclidMullinTerm(input[0]);
}

const SMALL_PRIMES = [_]i64{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61};

fn gcdI64(left_input: i64, right_input: i64) i64 {
    var left = left_input;
    var right = right_input;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

fn powModI64(base_input: i64, exponent_input: i64, modulus: i64) i64 {
    var result: i64 = 1;
    var base = @mod(base_input, modulus);
    var exponent = exponent_input;
    while (exponent > 0) {
        if (@mod(exponent, 2) != 0) result = @mod(result * base, modulus);
        base = @mod(base * base, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

export fn pollard_p_minus_one_factorization(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 3) return -1;
    const values = input.?[0..length];
    const number = values[0];
    const bound = values[1];
    const initial = values[2];
    if (number < 2 or number > 1000000000 or bound < 2 or bound > 64 or initial < 1 or initial >= number) return -1;
    var divisor = gcdI64(initial, number);
    if (divisor > 1) return divisor;
    var state = initial;
    for (SMALL_PRIMES) |prime| {
        if (prime > bound) break;
        var exponent = prime;
        while (exponent <= @divTrunc(bound, prime)) exponent *= prime;
        state = powModI64(state, exponent, number);
        const difference = if (state >= 1) state - 1 else 1 - state;
        divisor = gcdI64(difference, number);
        if (divisor > 1) return if (divisor < number) divisor else 0;
    }
    return 0;
}

/// Carmichael's universal exponent by prime-power factorization.
const MAX_N: i64 = 1_024;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn gcdI64(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

fn lcmI64(left: i64, right: i64) i64 {
    return @divTrunc(left, gcdI64(left, right)) * right;
}

fn primePowerLambda(prime: i64, exponent: usize, power: i64) i64 {
    if (prime == 2) {
        if (exponent == 1) return 1;
        if (exponent == 2) return 2;
        return @divTrunc(power, 4);
    }
    return @divTrunc(power, prime) * (prime - 1);
}

fn factorizationLambda(n: i64) i64 {
    if (n == 1) return 1;
    var remaining = n;
    var result: i64 = 1;
    var prime: i64 = 2;
    while (prime * prime <= remaining) {
        if (@rem(remaining, prime) != 0) {
            if (prime == 2) prime = 3 else prime += 2;
            continue;
        }
        var exponent: usize = 0;
        var power: i64 = 1;
        while (@rem(remaining, prime) == 0) {
            remaining = @divTrunc(remaining, prime);
            power *= prime;
            exponent += 1;
        }
        result = lcmI64(result, primePowerLambda(prime, exponent, power));
        if (prime == 2) prime = 3 else prime += 2;
    }
    if (remaining > 1) result = lcmI64(result, remaining - 1);
    return result;
}

export fn carmichael_lambda_function(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const n = input.?[0];
    if (n < 1 or n > MAX_N or length != 1) return -1;
    return factorizationLambda(n);
}

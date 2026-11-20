module carmichael_lambda_function;

const long MAX_N = 1024;
const usz MAX_PARSEABLE_LENGTH = 2;

fn long gcd_i64(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long lcm_i64(long left, long right) {
    return left / gcd_i64(left, right) * right;
}

fn long prime_power_lambda(long prime, int exponent, long power) {
    if (prime == 2) {
        if (exponent == 1) return 1;
        if (exponent == 2) return 2;
        return power / 4;
    }
    return (power / prime) * (prime - 1);
}

fn long factorization_lambda(long n) {
    if (n == 1) return 1;
    long remaining = n;
    long result = 1;
    for (long prime = 2; prime * prime <= remaining; prime = (prime == 2 ? 3 : prime + 2)) {
        if (remaining % prime != 0) continue;
        int exponent = 0;
        long power = 1;
        do {
            remaining /= prime;
            power *= prime;
            exponent++;
        } while (remaining % prime == 0);
        result = lcm_i64(result, prime_power_lambda(prime, exponent, power));
    }
    if (remaining > 1) result = lcm_i64(result, remaining - 1);
    return result;
}

fn long carmichael_lambda_function(long* input, usz length)
        @export("carmichael_lambda_function") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    long n = input[0];
    if (n < 1 || n > MAX_N || length != 1) return -1;
    return factorization_lambda(n);
}

module sum_of_exponential_times_polynomial;

const long MODULUS = 998244353;
const usz MAX_DEGREE = 32;

fn void sepm_shift(long* source, long shift, usz degree,
                   long* choose, long* destination) {
    long[33] powers = zeroed;
    powers[0] = 1;
    shift %= MODULUS;
    for (usz i = 1; i <= degree; i++) powers[i] = powers[i - 1] * shift % MODULUS;
    for (usz d = 0; d <= degree; d++) {
        long total = 0;
        for (usz k = 0; k <= d; k++) {
            long term = choose[d * 33 + k] * powers[d - k] % MODULUS;
            total = (total + term * source[k]) % MODULUS;
        }
        destination[d] = total;
    }
}

fn long sum_of_exponential_times_polynomial(long* input, usz length) @export("sum_of_exponential_times_polynomial") {
    if (input == null || length != 3) return -1;
    long r = input[0];
    long degree_value = input[1];
    long n_value = input[2];
    if (r < 0 || r >= MODULUS || degree_value < 0 || degree_value > 32 || n_value < 0 || n_value > 1000000000000000000) return -1;
    usz degree = (usz)degree_value;
    long[1089] choose = zeroed;
    choose[0] = 1;
    for (usz d = 1; d <= degree; d++) {
        choose[d * 33] = 1;
        choose[d * 33 + d] = 1;
        for (usz k = 1; k < d; k++) choose[d * 33 + k] = (choose[(d - 1) * 33 + k - 1] + choose[(d - 1) * 33 + k]) % MODULUS;
    }

    long[33] accumulated = zeroed;
    long[33] block = zeroed;
    long[33] shifted = zeroed;
    block[0] = 1;
    long accumulated_power = 1;
    long block_power = r;
    long accumulated_length = 0;
    long block_length = 1;
    long remaining = n_value;
    while (remaining > 0) {
        if (remaining % 2 == 1) {
            sepm_shift(&block[0], accumulated_length, degree, &choose[0], &shifted[0]);
            for (usz d = 0; d <= degree; d++) accumulated[d] = (accumulated[d] + accumulated_power * shifted[d]) % MODULUS;
            accumulated_power = accumulated_power * block_power % MODULUS;
            accumulated_length += block_length;
        }
        sepm_shift(&block[0], block_length, degree, &choose[0], &shifted[0]);
        for (usz d = 0; d <= degree; d++) block[d] = (block[d] + block_power * shifted[d]) % MODULUS;
        block_power = block_power * block_power % MODULUS;
        block_length *= 2;
        remaining /= 2;
    }
    return accumulated[degree];
}

module elliptic_curve_method_stage1;

const usz PRIME_COUNT = 11;
const long[PRIME_COUNT] STAGE1_PRIMES = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31};

fn long mod_norm(long value, long modulus) {
    value %= modulus;
    return value < 0 ? value + modulus : value;
}

fn long gcd_i64(long left, long right) {
    if (left < 0) left = -left;
    if (right < 0) right = -right;
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn bool square_free(long number) {
    for (long divisor = 2; divisor * divisor <= number; divisor++) {
        if (number % (divisor * divisor) == 0) return false;
    }
    return true;
}

fn void x_double(long x, long z, long a24, long modulus, long* out_x, long* out_z) {
    long plus = mod_norm(x + z, modulus);
    long minus = mod_norm(x - z, modulus);
    long plus_sq = plus * plus % modulus;
    long minus_sq = minus * minus % modulus;
    long delta = mod_norm(plus_sq - minus_sq, modulus);
    *out_x = plus_sq * minus_sq % modulus;
    *out_z = delta * mod_norm(minus_sq + a24 * delta, modulus) % modulus;
}

fn void x_add(long x1, long z1, long x2, long z2, long diff_x, long diff_z,
              long modulus, long* out_x, long* out_z) {
    long first = mod_norm(x1 - z1, modulus) * mod_norm(x2 + z2, modulus) % modulus;
    long second = mod_norm(x1 + z1, modulus) * mod_norm(x2 - z2, modulus) % modulus;
    long sum_term = mod_norm(first + second, modulus);
    long difference_term = mod_norm(first - second, modulus);
    *out_x = diff_z * sum_term % modulus * sum_term % modulus;
    *out_z = diff_x * difference_term % modulus * difference_term % modulus;
}

fn void x_multiply(long point_x, long point_z, long scalar, long a24, long modulus,
                   long* out_x, long* out_z) {
    long r0_x = 1, r0_z = 0;
    long r1_x = point_x, r1_z = point_z;
    long copy = scalar;
    int highest = 0;
    while (copy > 1) { copy >>= 1; highest++; }
    for (int bit = highest; bit >= 0; bit--) {
        long sum_x, sum_z, doubled_x, doubled_z;
        if ((scalar & (1L << bit)) != 0) {
            x_add(r0_x, r0_z, r1_x, r1_z, point_x, point_z, modulus, &sum_x, &sum_z);
            x_double(r1_x, r1_z, a24, modulus, &doubled_x, &doubled_z);
            r0_x = sum_x; r0_z = sum_z; r1_x = doubled_x; r1_z = doubled_z;
        } else {
            x_add(r0_x, r0_z, r1_x, r1_z, point_x, point_z, modulus, &sum_x, &sum_z);
            x_double(r0_x, r0_z, a24, modulus, &doubled_x, &doubled_z);
            r1_x = sum_x; r1_z = sum_z; r0_x = doubled_x; r0_z = doubled_z;
        }
    }
    *out_x = r0_x;
    *out_z = r0_z;
}

fn long elliptic_curve_method_stage1(long* input, usz length) @export("elliptic_curve_method_stage1") {
    if (input == null || length != 5) return -1;
    long number = input[0], curve_a = input[1], point_x = input[2];
    long point_y = input[3], bound = input[4];
    if (number < 3 || number > 10000 || (number & 1) == 0 || bound < 2 || bound > 32
        || curve_a < 0 || curve_a >= number || point_x < 0 || point_x >= number
        || point_y < 0 || point_y >= number || !square_free(number)) return -1;
    if (gcd_i64(curve_a * curve_a - 4, number) != 1) return -1;
    long x_sq = point_x * point_x % number;
    long rhs = (x_sq * point_x + curve_a * x_sq + point_x) % number;
    if (point_y * point_y % number != rhs) return -1;
    long inverse_four = number % 4 == 3 ? (number + 1) / 4 : (3 * number + 1) / 4;
    long a24 = (curve_a + 2) * inverse_four % number;
    long x = point_x, z = 1;
    for (usz index = 0; index < PRIME_COUNT; index++) {
        long prime = STAGE1_PRIMES[index];
        if (prime > bound) break;
        long prime_power = prime;
        while (prime_power <= bound / prime) prime_power *= prime;
        x_multiply(x, z, prime_power, a24, number, &x, &z);
        long divisor = gcd_i64(z, number);
        if (divisor > 1) return divisor < number ? 1 : 0;
    }
    return 0;
}

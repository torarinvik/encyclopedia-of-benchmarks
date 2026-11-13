#include <stddef.h>
#include <stdint.h>

static const int64_t STAGE1_PRIMES[] = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31};

static int64_t mod_norm(int64_t value, int64_t modulus) {
    value %= modulus;
    return value < 0 ? value + modulus : value;
}

static int64_t gcd_i64(int64_t left, int64_t right) {
    if (left < 0) left = -left;
    if (right < 0) right = -right;
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static int square_free(int64_t number) {
    for (int64_t divisor = 2; divisor * divisor <= number; ++divisor) {
        if (number % (divisor * divisor) == 0) return 0;
    }
    return 1;
}

static void x_double(int64_t x, int64_t z, int64_t a24, int64_t modulus,
                     int64_t *out_x, int64_t *out_z) {
    const int64_t plus = mod_norm(x + z, modulus);
    const int64_t minus = mod_norm(x - z, modulus);
    const int64_t plus_sq = plus * plus % modulus;
    const int64_t minus_sq = minus * minus % modulus;
    const int64_t delta = mod_norm(plus_sq - minus_sq, modulus);
    *out_x = plus_sq * minus_sq % modulus;
    *out_z = delta * mod_norm(minus_sq + a24 * delta, modulus) % modulus;
}

static void x_add(int64_t x1, int64_t z1, int64_t x2, int64_t z2,
                  int64_t diff_x, int64_t diff_z, int64_t modulus,
                  int64_t *out_x, int64_t *out_z) {
    const int64_t first = mod_norm(x1 - z1, modulus) * mod_norm(x2 + z2, modulus) % modulus;
    const int64_t second = mod_norm(x1 + z1, modulus) * mod_norm(x2 - z2, modulus) % modulus;
    const int64_t sum_term = mod_norm(first + second, modulus);
    const int64_t difference_term = mod_norm(first - second, modulus);
    *out_x = diff_z * sum_term % modulus * sum_term % modulus;
    *out_z = diff_x * difference_term % modulus * difference_term % modulus;
}

static void x_multiply(int64_t point_x, int64_t point_z, int64_t scalar,
                       int64_t a24, int64_t modulus, int64_t *out_x, int64_t *out_z) {
    int64_t r0_x = 1, r0_z = 0;
    int64_t r1_x = point_x, r1_z = point_z;
    int highest = 0;
    for (int64_t copy = scalar; copy > 1; copy >>= 1) ++highest;
    for (int bit = highest; bit >= 0; --bit) {
        int64_t sum_x, sum_z, doubled_x, doubled_z;
        if ((scalar & (INT64_C(1) << bit)) != 0) {
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

int64_t elliptic_curve_method_stage1(const int64_t *input, size_t length) {
    if (input == NULL || length != 5) return -1;
    const int64_t number = input[0], curve_a = input[1], point_x = input[2];
    const int64_t point_y = input[3], bound = input[4];
    if (number < 3 || number > 10000 || (number & 1) == 0 || bound < 2 || bound > 32
        || curve_a < 0 || curve_a >= number || point_x < 0 || point_x >= number
        || point_y < 0 || point_y >= number || !square_free(number)) return -1;
    if (gcd_i64(curve_a * curve_a - 4, number) != 1) return -1;
    const int64_t x_sq = point_x * point_x % number;
    const int64_t rhs = (x_sq * point_x + curve_a * x_sq + point_x) % number;
    if (point_y * point_y % number != rhs) return -1;
    const int64_t inverse_four = number % 4 == 3 ? (number + 1) / 4 : (3 * number + 1) / 4;
    const int64_t a24 = (curve_a + 2) * inverse_four % number;
    int64_t x = point_x, z = 1;
    for (size_t index = 0; index < sizeof(STAGE1_PRIMES) / sizeof(STAGE1_PRIMES[0]); ++index) {
        const int64_t prime = STAGE1_PRIMES[index];
        if (prime > bound) break;
        int64_t prime_power = prime;
        while (prime_power <= bound / prime) prime_power *= prime;
        x_multiply(x, z, prime_power, a24, number, &x, &z);
        const int64_t divisor = gcd_i64(z, number);
        if (divisor > 1) return divisor < number ? 1 : 0;
    }
    return 0;
}

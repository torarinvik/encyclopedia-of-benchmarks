#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::array<std::int64_t, 11> STAGE1_PRIMES = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31};

std::int64_t mod_norm(std::int64_t value, std::int64_t modulus) {
    value %= modulus;
    return value < 0 ? value + modulus : value;
}

std::int64_t gcd_i64(std::int64_t left, std::int64_t right) {
    if (left < 0) left = -left;
    if (right < 0) right = -right;
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

bool square_free(std::int64_t number) {
    for (std::int64_t divisor = 2; divisor * divisor <= number; ++divisor) {
        if (number % (divisor * divisor) == 0) return false;
    }
    return true;
}

struct XPoint { std::int64_t x, z; };

XPoint x_double(XPoint point, std::int64_t a24, std::int64_t modulus) {
    const auto plus = mod_norm(point.x + point.z, modulus);
    const auto minus = mod_norm(point.x - point.z, modulus);
    const auto plus_sq = plus * plus % modulus;
    const auto minus_sq = minus * minus % modulus;
    const auto delta = mod_norm(plus_sq - minus_sq, modulus);
    return {plus_sq * minus_sq % modulus,
            delta * mod_norm(minus_sq + a24 * delta, modulus) % modulus};
}

XPoint x_add(XPoint left, XPoint right, XPoint difference, std::int64_t modulus) {
    const auto first = mod_norm(left.x - left.z, modulus)
                     * mod_norm(right.x + right.z, modulus) % modulus;
    const auto second = mod_norm(left.x + left.z, modulus)
                      * mod_norm(right.x - right.z, modulus) % modulus;
    const auto sum_term = mod_norm(first + second, modulus);
    const auto difference_term = mod_norm(first - second, modulus);
    return {difference.z * sum_term % modulus * sum_term % modulus,
            difference.x * difference_term % modulus * difference_term % modulus};
}

XPoint x_multiply(XPoint point, std::int64_t scalar, std::int64_t a24, std::int64_t modulus) {
    XPoint r0{1, 0}, r1 = point;
    int highest = 0;
    for (auto copy = scalar; copy > 1; copy >>= 1) ++highest;
    for (int bit = highest; bit >= 0; --bit) {
        if ((scalar & (std::int64_t{1} << bit)) != 0) {
            r0 = x_add(r0, r1, point, modulus);
            r1 = x_double(r1, a24, modulus);
        } else {
            r1 = x_add(r0, r1, point, modulus);
            r0 = x_double(r0, a24, modulus);
        }
    }
    return r0;
}
}

extern "C" std::int64_t elliptic_curve_method_stage1(const std::int64_t *input,
                                                      std::size_t length) noexcept {
    if (input == nullptr || length != 5) return -1;
    const auto number = input[0], curve_a = input[1], point_x = input[2];
    const auto point_y = input[3], bound = input[4];
    if (number < 3 || number > 10000 || (number & 1) == 0 || bound < 2 || bound > 32
        || curve_a < 0 || curve_a >= number || point_x < 0 || point_x >= number
        || point_y < 0 || point_y >= number || !square_free(number)) return -1;
    if (gcd_i64(curve_a * curve_a - 4, number) != 1) return -1;
    const auto x_sq = point_x * point_x % number;
    const auto rhs = (x_sq * point_x + curve_a * x_sq + point_x) % number;
    if (point_y * point_y % number != rhs) return -1;
    const auto inverse_four = number % 4 == 3 ? (number + 1) / 4 : (3 * number + 1) / 4;
    const auto a24 = (curve_a + 2) * inverse_four % number;
    XPoint point{point_x, 1};
    for (const auto prime : STAGE1_PRIMES) {
        if (prime > bound) break;
        auto prime_power = prime;
        while (prime_power <= bound / prime) prime_power *= prime;
        point = x_multiply(point, prime_power, a24, number);
        const auto divisor = gcd_i64(point.z, number);
        if (divisor > 1) return divisor < number ? 1 : 0;
    }
    return 0;
}

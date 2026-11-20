#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_prime = 1'000'000;
constexpr std::size_t max_length = 3;
constexpr std::int64_t pack_base = 1024;

bool is_prime(std::int64_t value) {
    if (value < 2) return false;
    for (std::int64_t divisor = 2; divisor <= value / divisor;
         divisor = divisor == 2 ? 3 : divisor + 2)
        if (value % divisor == 0) return false;
    return true;
}

std::int64_t isqrt(std::int64_t value) {
    std::int64_t low = 0, high = 1001;
    while (low + 1 < high) {
        const auto middle = (low + high) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}
}

extern "C" std::int64_t cornacchia_x2_plus_2y2(const std::int64_t* input,
                                                std::size_t length) {
    if (input == nullptr || length < 2 || length > max_length) return -1;
    const auto prime = input[0], root = input[1];
    if (prime < 3 || prime > max_prime || (prime & 1) == 0 ||
        root < 1 || root > prime / 2 || length != 2) return -1;
    if (!is_prime(prime) || (root * root + 2) % prime != 0) return -1;

    auto previous = prime;
    auto current = root;
    const auto limit = isqrt(prime);
    while (current > limit) {
        const auto remainder = previous % current;
        previous = current;
        current = remainder;
    }
    const auto x = current;
    const auto numerator = prime - x * x;
    if (numerator <= 0 || numerator % 2 != 0) return -1;
    const auto y_squared = numerator / 2;
    const auto y = isqrt(y_squared);
    if (y <= 0 || y * y != y_squared || x * x + 2 * y * y != prime) return -1;
    return x * pack_base + y;
}

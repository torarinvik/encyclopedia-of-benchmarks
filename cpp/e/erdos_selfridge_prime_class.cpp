#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxPrime = 100'000;

bool is_prime(std::int64_t value) {
    if (value < 2) return false;
    if (value % 2 == 0) return value == 2;
    for (std::int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

std::int64_t class_for_prime(std::int64_t prime, std::int64_t direction) {
    std::int64_t remainder = prime + direction;
    std::int64_t best = 1;
    for (std::int64_t divisor = 2; divisor <= remainder / divisor; ++divisor) {
        if (remainder % divisor != 0) continue;
        if (divisor > 3) {
            const auto candidate = 1 + class_for_prime(divisor, direction);
            if (candidate > best) best = candidate;
        }
        do { remainder /= divisor; } while (remainder % divisor == 0);
    }
    if (remainder > 3) {
        const auto candidate = 1 + class_for_prime(remainder, direction);
        if (candidate > best) best = candidate;
    }
    return best;
}
}

extern "C" std::int64_t erdos_selfridge_prime_class(const std::int64_t* input,
                                                     std::size_t length) {
    if (input == nullptr || length < 1 || length > 3) return -1;
    if (length != 2) return -1;
    const auto prime = input[0];
    const auto direction = input[1];
    if (prime < 2 || prime > kMaxPrime || (direction != -1 && direction != 1)) return -1;
    if (!is_prime(prime)) return -1;
    return class_for_prime(prime, direction);
}


#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_limit = 100000;
constexpr std::size_t sieve_length = 200001;
}

extern "C" std::int64_t strong_weak_balanced_prime_distribution(
        const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 1 || length > 2) return -1;
    const std::int64_t limit = input[0];
    if (length != 1 || limit < 3 || limit > max_limit) return -1;

    const std::int64_t ceiling = 2 * limit;
    std::array<bool, sieve_length> prime{};
    prime.fill(true);
    prime[0] = prime[1] = false;
    for (std::int64_t divisor = 2; divisor * divisor <= ceiling; ++divisor) {
        if (!prime[static_cast<std::size_t>(divisor)]) continue;
        for (std::int64_t multiple = divisor * divisor; multiple <= ceiling; multiple += divisor)
            prime[static_cast<std::size_t>(multiple)] = false;
    }

    std::int64_t strong = 0, weak = 0, balanced = 0;
    std::int64_t previous = 0, current = 0;
    for (std::int64_t candidate = 2; candidate <= ceiling; ++candidate) {
        if (!prime[static_cast<std::size_t>(candidate)]) continue;
        if (previous != 0 && current >= 3 && current <= limit) {
            const std::int64_t twice = 2 * current;
            const std::int64_t neighbors = previous + candidate;
            if (twice > neighbors) ++strong;
            else if (twice < neighbors) ++weak;
            else ++balanced;
        }
        previous = current;
        current = candidate;
    }
    return strong * 10000000000LL + weak * 100000LL + balanced;
}

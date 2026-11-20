#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxInputLength = 2;
constexpr std::uint32_t kMaxValue = 600000;
constexpr std::int64_t kMaxK = 50000;

void build_prime_prefix(std::uint32_t* prefix) {
    prefix[0] = 0;
    prefix[1] = 0;
    for (std::uint32_t value = 2; value <= kMaxValue; ++value) prefix[value] = 1;
    for (std::uint32_t prime = 2; prime <= kMaxValue / prime; ++prime) {
        if (prefix[prime] != 0) {
            for (std::uint32_t multiple = prime * prime; multiple <= kMaxValue; multiple += prime)
                prefix[multiple] = 0;
        }
    }
    for (std::uint32_t value = 1; value <= kMaxValue; ++value)
        prefix[value] += prefix[value - 1];
}

bool is_prime(std::uint32_t value, const std::uint32_t* prefix) noexcept {
    return value >= 2 && prefix[value] - prefix[value - 1] == 1;
}

std::int64_t count_tau_eight(std::uint32_t limit, const std::uint32_t* prefix) noexcept {
    std::int64_t count = 0;
    for (std::uint64_t prime = 2;; ++prime) {
        std::uint64_t power = 1;
        for (int exponent = 0; exponent < 7; ++exponent) {
            if (power > limit / prime) { power = static_cast<std::uint64_t>(limit) + 1; break; }
            power *= prime;
        }
        if (power > limit) break;
        if (is_prime(static_cast<std::uint32_t>(prime), prefix)) ++count;
    }
    for (std::uint64_t prime = 2;; ++prime) {
        const std::uint64_t cube = prime * prime * prime;
        if (cube > limit) break;
        if (is_prime(static_cast<std::uint32_t>(prime), prefix)) {
            const auto q_max = static_cast<std::uint32_t>(limit / cube);
            count += prefix[q_max];
            if (prime <= q_max) --count;
        }
    }
    for (std::uint64_t prime = 2; prime * prime * prime < limit; ++prime) {
        if (!is_prime(static_cast<std::uint32_t>(prime), prefix)) continue;
        for (std::uint64_t other = prime + 1;; ++other) {
            if (prime > limit / other) break;
            const auto product = prime * other;
            const auto last_prime = static_cast<std::uint32_t>(limit / product);
            if (last_prime <= other) break;
            if (is_prime(static_cast<std::uint32_t>(other), prefix))
                count += prefix[last_prime] - prefix[static_cast<std::uint32_t>(other)];
        }
    }
    return count;
}
}

extern "C" std::int64_t cube_root_proper_divisor_product(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > kMaxInputLength) return -1;
    if (length != 1 || input[0] < 1 || input[0] > kMaxK) return -1;
    if (input[0] == 1) return 1;
    std::array<std::uint32_t, kMaxValue + 1> prime_prefix{};
    build_prime_prefix(prime_prefix.data());
    const auto target = input[0] - 1;
    if (count_tau_eight(kMaxValue, prime_prefix.data()) < target) return -1;
    std::uint32_t low = 1;
    std::uint32_t high = kMaxValue;
    while (low < high) {
        const auto middle = low + (high - low) / 2;
        if (count_tau_eight(middle, prime_prefix.data()) >= target) high = middle;
        else low = middle + 1;
    }
    return low;
}

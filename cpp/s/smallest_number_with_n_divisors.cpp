#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input = 3;
constexpr std::size_t max_stack = 128;
constexpr std::int64_t max_divisor_count = 63;
constexpr std::int64_t max_limit = 1'000'000;
constexpr std::array<std::int64_t, 5> primes{2, 3, 5, 7, 11};
}

extern "C" std::int64_t smallest_number_with_n_divisors(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input || length != 2) return -1;
    const std::int64_t divisor_count = input[0], limit = input[1];
    if (divisor_count < 1 || divisor_count > max_divisor_count || limit < 1 || limit > max_limit) return -1;

    std::array<std::int64_t, max_stack> remaining_stack{};
    std::array<std::int64_t, max_stack> max_factor_stack{};
    std::array<std::int64_t, max_stack> prime_index_stack{};
    std::array<std::int64_t, max_stack> product_stack{};
    std::size_t top = 1;
    remaining_stack[0] = divisor_count;
    max_factor_stack[0] = divisor_count;
    product_stack[0] = 1;
    std::int64_t best = limit + 1;

    while (top != 0) {
        --top;
        const auto remaining = remaining_stack[top];
        const auto max_factor = max_factor_stack[top];
        const auto prime_index = prime_index_stack[top];
        const auto product = product_stack[top];
        if (remaining == 1) {
            if (product < best) best = product;
            continue;
        }
        if (prime_index >= static_cast<std::int64_t>(primes.size())) continue;
        const auto prime = primes[static_cast<std::size_t>(prime_index)];
        const auto factor_limit = max_factor < remaining ? max_factor : remaining;
        for (std::int64_t factor = 2; factor <= factor_limit; ++factor) {
            if (remaining % factor != 0) continue;
            auto candidate = product;
            bool valid = true;
            for (std::int64_t step = 1; step < factor; ++step) {
                if (candidate > limit / prime) { valid = false; break; }
                candidate *= prime;
            }
            if (valid && candidate < best) {
                if (top >= max_stack) return -1;
                remaining_stack[top] = remaining / factor;
                max_factor_stack[top] = factor;
                prime_index_stack[top] = prime_index + 1;
                product_stack[top] = candidate;
                ++top;
            }
        }
    }
    return best <= limit ? best : 0;
}

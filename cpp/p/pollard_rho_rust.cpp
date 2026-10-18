#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_num = 1'000'000'000;
constexpr std::int64_t u32_mod = 4'294'967'296;
constexpr std::int64_t iterations_before_check = 32;
constexpr std::int64_t iterations_cutoff = 262'144;

std::int64_t gcd_nonnegative(std::int64_t left, std::int64_t right) noexcept {
    while (left != 0) {
        const auto remainder = right % left;
        right = left;
        left = remainder;
    }
    return right;
}

std::int64_t mod_power(std::int64_t base, std::int64_t power, std::int64_t modulus) noexcept {
    base %= modulus;
    if (base == 0) return 0;
    std::int64_t result = 1;
    while (power > 0) {
        if (power % 2 != 0) result = result * base % modulus;
        base = base * base % modulus;
        power /= 2;
    }
    return result;
}

bool probable_prime(std::int64_t number) noexcept {
    if (number <= 4) return number == 2 || number == 3;
    constexpr std::int64_t bases[] = {2, 3, 5, 7};
    for (const auto base : bases) if (number == base) return true;
    auto odd_power = number - 1;
    std::int64_t two_power = 0;
    while (odd_power % 2 == 0) { odd_power /= 2; ++two_power; }
    for (const auto base : bases) {
        auto value = mod_power(base, odd_power, number);
        if (value == 1 || value == number - 1) continue;
        bool passed = false;
        for (std::int64_t r = 1; r < two_power; ++r) {
            value = value * value % number;
            if (value == number - 1) { passed = true; break; }
        }
        if (!passed) return false;
    }
    return true;
}

std::int64_t lcg_next(std::int64_t &state) noexcept {
    state = (1'103'515'245LL * state + 12'345) % u32_mod;
    return state;
}

std::int64_t draw_mod(std::int64_t &state, std::int64_t modulus) noexcept {
    const auto high = lcg_next(state);
    const auto low = lcg_next(state);
    return ((high % modulus) * (u32_mod % modulus) + low % modulus) % modulus;
}

std::int64_t advance(std::int64_t x, std::int64_t c, std::int64_t number) noexcept {
    return (x * x + c) % number;
}

std::int64_t brent_factor(std::int64_t number, std::int64_t x0, std::int64_t c) noexcept {
    auto x = x0;
    std::int64_t x_start = 0, y = 0, remainder = 1, current_gcd = 1;
    std::int64_t max_iterations = 1;
    while (current_gcd == 1) {
        y = x;
        for (std::int64_t i = 1; i < max_iterations; ++i) x = advance(x, c, number);
        std::int64_t big_iteration = 0;
        while (big_iteration < max_iterations && current_gcd == 1) {
            x_start = x;
            std::int64_t small_iteration = 0;
            while (small_iteration < iterations_before_check &&
                   small_iteration < max_iterations - big_iteration) {
                ++small_iteration;
                x = advance(x, c, number);
                const auto difference = x >= y ? x - y : y - x;
                remainder = remainder * difference % number;
            }
            current_gcd = gcd_nonnegative(remainder, number);
            big_iteration += iterations_before_check;
        }
        max_iterations *= 2;
        if (max_iterations > iterations_cutoff) break;
    }
    if (current_gcd == number) {
        while (current_gcd == 1) {
            x_start = advance(x_start, c, number);
            const auto difference = x_start >= y ? x_start - y : y - x_start;
            current_gcd = gcd_nonnegative(difference, number);
        }
    }
    return current_gcd;
}
}

extern "C" std::int64_t pollard_rho_rust(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 3) return -1;
    const auto number = input[0];
    auto state = input[1];
    const auto restart_limit = input[2];
    if (number < 2 || number > max_num || state < 0 || state >= u32_mod ||
        restart_limit < 1 || restart_limit > 16) return -1;
    if (probable_prime(number)) return number;

    for (std::int64_t restart = 0; restart < restart_limit; ++restart) {
        const auto x0 = draw_mod(state, number - 3) + 2;
        const auto c = draw_mod(state, number - 2) + 1;
        const auto factor = brent_factor(number, x0, c);
        if (factor != 1 && factor != number) return factor;
    }
    return 0;
}

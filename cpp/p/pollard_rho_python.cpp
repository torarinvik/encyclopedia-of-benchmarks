#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_num = 1'000'000;

std::int64_t gcd_nonnegative(std::int64_t left, std::int64_t right) noexcept {
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

std::int64_t advance(std::int64_t value, std::int64_t step, std::int64_t modulus) noexcept {
    return (value * value + step) % modulus;
}
}

extern "C" std::int64_t pollard_rho_python(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 5) return -1;
    const auto num = input[0];
    auto seed = input[1];
    auto step = input[2];
    const auto attempts = input[3];
    const auto step_limit = input[4];
    if (num < 2 || num > max_num || seed < 0 || seed >= num || step < 0 || step > 1000 ||
        attempts < 1 || attempts > 8 || step_limit < 1 || step_limit > 64) return -1;
    if (num > 2 && num % 2 == 0) return 2;

    for (std::int64_t attempt = 0; attempt < attempts; ++attempt) {
        auto tortoise = seed;
        auto hare = seed;
        for (std::int64_t iteration = 0; iteration < step_limit; ++iteration) {
            tortoise = advance(tortoise, step, num);
            hare = advance(advance(hare, step, num), step, num);
            const auto difference = hare >= tortoise ? hare - tortoise : tortoise - hare;
            const auto divisor = gcd_nonnegative(difference, num);
            if (divisor == 1) continue;
            if (divisor < num) return divisor;
            break;
        }
        seed = hare;
        ++step;
    }
    return 0;
}

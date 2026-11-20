#include <cstddef>
#include <cstdint>

namespace {
std::int64_t integer_sqrt_i64(std::int64_t value, std::int64_t upper) {
    std::int64_t low = 0;
    std::int64_t high = upper + 1;
    while (low + 1 < high) {
        const auto middle = low + (high - low) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}
}

extern "C" std::int64_t fermat_factorization(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 2) return -1;
    const auto number = input[0];
    const auto max_steps = input[1];
    if (number < 3 || number > 1000000000000LL || number % 2 == 0
        || max_steps < 0 || max_steps > 4096) return -1;
    auto candidate = integer_sqrt_i64(number, 1000000);
    if (candidate * candidate < number) ++candidate;
    for (std::int64_t step = 0; step < max_steps; ++step, ++candidate) {
        const auto difference = candidate * candidate - number;
        const auto root = integer_sqrt_i64(difference, candidate);
        if (root * root == difference) {
            const auto factor = candidate - root;
            if (factor > 1 && factor < number) return factor;
        }
    }
    return 0;
}

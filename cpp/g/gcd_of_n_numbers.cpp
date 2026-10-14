/* Fold positive signed 32-bit values with Euclid's GCD algorithm. */
#include <cstddef>
#include <cstdint>

static std::int64_t gcd_pair(std::int64_t left, std::int64_t right) noexcept {
    while (right != 0) {
        const std::int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

extern "C" std::int64_t gcd_of_n_numbers(const std::int64_t *values,
                                           std::size_t length) noexcept {
    if (length == 0 || length > 64) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < 1 || values[index] > INT32_MAX) return -1;
    std::int64_t result = values[0];
    for (std::size_t index = 1; index < length && result != 1; ++index)
        result = gcd_pair(result, values[index]);
    return result;
}

// Multiply bounded nonnegative operands with a three-product decimal split.
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
int decimal_digits(std::int64_t value) {
    int digits = 1;
    while (value >= 10) { value /= 10; ++digits; }
    return digits;
}

std::int64_t karatsuba_product(std::int64_t left, std::int64_t right) {
    if (left < 10 || right < 10) return left * right;
    const int digits = decimal_digits(std::max(left, right));
    std::int64_t split = 1;
    for (int index = 0; index < digits / 2; ++index) split *= 10;
    const std::int64_t left_high = left / split, left_low = left % split;
    const std::int64_t right_high = right / split, right_low = right % split;
    const std::int64_t low_product = karatsuba_product(left_low, right_low);
    const std::int64_t high_product = karatsuba_product(left_high, right_high);
    const std::int64_t sum_product = karatsuba_product(left_high + left_low, right_high + right_low);
    return high_product * split * split + (sum_product - high_product - low_product) * split + low_product;
}
}

extern "C" std::int64_t karatsuba(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length != 2) return -1;
    if (input[0] < 0 || input[0] > 1000000 || input[1] < 0 || input[1] > 1000000) return -1;
    return karatsuba_product(input[0], input[1]);
}

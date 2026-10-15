// Add nonnegative integers by recursively propagating XOR carries.
#include <cstdint>

namespace {
std::int64_t add_recursive(std::int64_t first, std::int64_t second) {
    const auto bitwise_sum = first ^ second;
    const auto carry = first & second;
    return carry == 0 ? bitwise_sum : add_recursive(bitwise_sum, carry << 1);
}
}

extern "C" std::int64_t bitwise_addition_recursive(std::int64_t first, std::int64_t second) noexcept {
    if (first < 0 || first > 2147483647 || second < 0 || second > 2147483647) return -1;
    return add_recursive(first, second);
}

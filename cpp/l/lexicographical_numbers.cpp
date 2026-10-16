#include <array>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t max_number = 4096; constexpr std::size_t stack_capacity = 4112; }

extern "C" std::int64_t lexicographical_numbers(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 1 || values[0] < 0 || values[0] > max_number) return -1;
    std::array<std::int64_t, stack_capacity> stack{};
    std::size_t top = 1; stack[0] = 1;
    std::int64_t index = 0, checksum = 0;
    while (top > 0) {
        const auto number = stack[--top];
        if (number <= values[0]) {
            checksum += (++index) * number;
            if (number % 10 != 9) stack[top++] = number + 1;
            stack[top++] = number * 10;
        }
    }
    return checksum;
}

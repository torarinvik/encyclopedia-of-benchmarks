/* Return source-compatible spans for a bounded price sequence. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t stock_span_problem(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 2 || length > 66) return -1;
    const std::int64_t count_value = input[0];
    if (count_value < 1 || count_value > 64) return -1;
    const std::size_t count = static_cast<std::size_t>(count_value);
    if (length != count + 1) return -1;
    for (std::size_t day = 0; day < count; ++day)
        if (input[day + 1] < INT32_MIN || input[day + 1] > INT32_MAX) return -1;

    const std::size_t output_bytes = count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::size_t decreasing[64];
    std::size_t top = 0;
    for (std::size_t day = 0; day < count; ++day) {
        const std::int64_t price = input[day + 1];
        while (top != 0 && input[decreasing[top - 1] + 1] <= price) --top;
        const std::size_t span = top == 0 ? day + 1 : day - decreasing[top - 1];
        const std::uint64_t encoded = static_cast<std::uint64_t>(span);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[day * 8 + byte] = static_cast<std::uint8_t>(encoded >> (byte * 8));
        decreasing[top++] = day;
    }
    return count_value;
}

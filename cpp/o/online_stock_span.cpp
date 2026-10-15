#include <cstddef>
#include <cstdint>

extern "C" std::int64_t online_stock_span(const std::int64_t *input, std::size_t length,
                                          std::uint8_t *output, std::size_t output_capacity)
{
    constexpr std::size_t max_days = 4095;
    if (input == nullptr || length < 2 || input[0] < 1 || input[0] > static_cast<std::int64_t>(max_days))
        return -1;
    const std::size_t count = static_cast<std::size_t>(input[0]);
    if (length != count + 1) return -1;
    for (std::size_t day = 0; day < count; ++day)
        if (input[day + 1] < 1 || input[day + 1] > 100000) return -1;
    const std::size_t output_bytes = count * 8;
    if (output_capacity < output_bytes || output == nullptr) return -2;

    std::size_t decreasing[max_days];
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
    return static_cast<std::int64_t>(count);
}

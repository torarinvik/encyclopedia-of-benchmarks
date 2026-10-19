#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH = 4096;

std::size_t decimal_digits(std::uint32_t value)
{
    std::size_t count = 1;
    while (value >= 10) { value /= 10; ++count; }
    return count;
}

void write_decimal(std::uint32_t value, std::uint8_t *output)
{
    std::uint8_t reversed[10];
    std::size_t count = 0;
    do { reversed[count++] = static_cast<std::uint8_t>('0' + value % 10); value /= 10; }
    while (value != 0);
    for (std::size_t index = 0; index < count; ++index)
        output[index] = reversed[count - index - 1];
}
}

extern "C" std::int64_t ary3(std::int64_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept
{
    if (length < 1 || length > static_cast<std::int64_t>(MAX_LENGTH)) return -1;
    const std::size_t n = static_cast<std::size_t>(length);
    std::int32_t x[MAX_LENGTH];
    std::int32_t y[MAX_LENGTH];
    for (std::size_t index = 0; index < n; ++index) {
        x[index] = static_cast<std::int32_t>(index + 1);
        y[index] = 0;
    }
    for (std::size_t pass = 0; pass < 1000; ++pass)
        for (std::size_t index = n; index > 0; --index) {
            const std::size_t position = index - 1;
            y[position] += x[position];
        }

    const std::uint32_t first = static_cast<std::uint32_t>(y[0]);
    const std::uint32_t last = static_cast<std::uint32_t>(y[n - 1]);
    const std::size_t first_digits = decimal_digits(first);
    const std::size_t required = first_digits + 2 + decimal_digits(last);
    if (output == nullptr || output_capacity < required) return -2;
    write_decimal(first, output);
    output[first_digits] = ' ';
    write_decimal(last, output + first_digits + 1);
    output[required - 1] = '\n';
    return static_cast<std::int64_t>(required);
}

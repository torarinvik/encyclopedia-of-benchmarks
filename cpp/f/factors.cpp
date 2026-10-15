// List all positive divisors in ascending decimal order.
#include <cstddef>
#include <cstdint>

static std::size_t decimal_length(std::int64_t value)
{
    std::size_t length = 1;
    while (value >= 10) { value /= 10; ++length; }
    return length;
}

static std::size_t append_decimal(std::int64_t value, std::uint8_t *output,
                                  std::size_t position)
{
    std::uint8_t digits[3];
    std::size_t count = 0;
    do { digits[count++] = static_cast<std::uint8_t>(value % 10); value /= 10; } while (value > 0);
    while (count > 0) output[position++] = static_cast<std::uint8_t>('0' + digits[--count]);
    return position;
}

extern "C" std::int64_t factors(std::int64_t value, std::uint8_t *output,
                                 std::size_t output_capacity)
{
    if (value < 1 || value > 256) return -1;
    std::size_t required = 0;
    std::size_t count = 0;
    for (std::int64_t divisor = 1; divisor <= value; ++divisor) {
        if (value % divisor == 0) { required += decimal_length(divisor) + (count != 0); ++count; }
    }
    if (output == nullptr || output_capacity < required) return -2;
    std::size_t position = 0;
    count = 0;
    for (std::int64_t divisor = 1; divisor <= value; ++divisor) {
        if (value % divisor == 0) {
            if (count != 0) output[position++] = ',';
            position = append_decimal(divisor, output, position);
            ++count;
        }
    }
    return static_cast<std::int64_t>(position);
}

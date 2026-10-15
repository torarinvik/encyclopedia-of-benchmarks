// Encode prime factors in ascending order, retaining multiplicity.
#include <cstddef>
#include <cstdint>

static std::size_t decimal_length(std::int64_t value)
{
    std::size_t length = 1;
    while (value >= 10) { value /= 10; ++length; }
    return length;
}

static std::size_t required_length(std::int64_t value)
{
    std::size_t length = 0, count = 0;
    auto remaining = value;
    for (std::int64_t divisor = 2; divisor <= remaining / divisor; ++divisor) {
        while (remaining % divisor == 0) {
            length += decimal_length(divisor) + (count != 0);
            ++count;
            remaining /= divisor;
        }
    }
    if (remaining > 1) length += decimal_length(remaining) + (count != 0);
    return length;
}

static std::size_t append_decimal(std::int64_t value, std::uint8_t *output,
                                  std::size_t position)
{
    std::uint8_t digits[10];
    std::size_t count = 0;
    do { digits[count++] = static_cast<std::uint8_t>(value % 10); value /= 10; } while (value > 0);
    while (count > 0) output[position++] = static_cast<std::uint8_t>('0' + digits[--count]);
    return position;
}

extern "C" std::int64_t prime_factors(std::int64_t value, std::uint8_t *output,
                                       std::size_t output_capacity)
{
    if (value < 1 || value > 2147483647) return -1;
    const auto required = required_length(value);
    if (output == nullptr || output_capacity < required) return -2;
    std::size_t position = 0, count = 0;
    auto remaining = value;
    for (std::int64_t divisor = 2; divisor <= remaining / divisor; ++divisor) {
        while (remaining % divisor == 0) {
            if (count != 0) output[position++] = ',';
            position = append_decimal(divisor, output, position);
            ++count;
            remaining /= divisor;
        }
    }
    if (remaining > 1) {
        if (count != 0) output[position++] = ',';
        position = append_decimal(remaining, output, position);
    }
    return static_cast<std::int64_t>(position);
}

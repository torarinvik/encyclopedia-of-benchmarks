// Encode all primes through an inclusive limit as comma-separated decimal bytes.
#include <cstddef>
#include <cstdint>

static bool is_prime(std::int64_t value)
{
    if (value < 2) return false;
    for (std::int64_t divisor = 2; divisor <= value / divisor; ++divisor)
        if (value % divisor == 0) return false;
    return true;
}

static std::size_t decimal_length(std::int64_t value)
{
    std::size_t length = 1;
    while (value >= 10) { value /= 10; ++length; }
    return length;
}

static std::size_t required_length(std::int64_t limit)
{
    std::size_t length = 0, count = 0;
    for (std::int64_t value = 2; value <= limit; ++value) {
        if (!is_prime(value)) continue;
        length += decimal_length(value) + (count != 0);
        ++count;
    }
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

extern "C" std::int64_t prime_numbers(std::int64_t limit, std::uint8_t *output,
                                       std::size_t output_capacity)
{
    if (limit < 0 || limit > 80) return -1;
    const auto required = required_length(limit);
    if (output == nullptr || output_capacity < required) return -2;
    std::size_t position = 0, count = 0;
    for (std::int64_t value = 2; value <= limit; ++value) {
        if (!is_prime(value)) continue;
        if (count != 0) output[position++] = ',';
        position = append_decimal(value, output, position);
        ++count;
    }
    return static_cast<std::int64_t>(position);
}

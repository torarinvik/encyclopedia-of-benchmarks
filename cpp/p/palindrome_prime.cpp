// Encode the first n palindrome primes as little-endian u32 values.
#include <cstddef>
#include <cstdint>

static bool is_prime(std::uint32_t value)
{
    if (value < 2) return false;
    for (std::uint32_t divisor = 2; divisor <= value / divisor; ++divisor)
        if (value % divisor == 0) return false;
    return true;
}

static std::uint32_t reverse_decimal(std::uint32_t value)
{
    std::uint32_t reversed = 0;
    while (value > 0) {
        reversed = reversed * 10 + value % 10;
        value /= 10;
    }
    return reversed;
}

static void write_u32_le(std::uint8_t *output, std::size_t position, std::uint32_t value)
{
    output[position] = static_cast<std::uint8_t>(value);
    output[position + 1] = static_cast<std::uint8_t>(value >> 8);
    output[position + 2] = static_cast<std::uint8_t>(value >> 16);
    output[position + 3] = static_cast<std::uint8_t>(value >> 24);
}

extern "C" std::int64_t palindrome_prime(std::int64_t n, std::uint8_t *output,
                                          std::size_t output_capacity)
{
    if (n > 16) return -1;
    if (n <= 0) return 0;
    const std::size_t required = static_cast<std::size_t>(n) * 4;
    if (output == nullptr || output_capacity < required) return -2;

    write_u32_le(output, 0, 2);
    std::size_t count = 1;
    for (std::uint32_t candidate = 3; count < static_cast<std::size_t>(n); candidate += 2) {
        if (candidate == reverse_decimal(candidate) && is_prime(candidate)) {
            write_u32_le(output, count * 4, candidate);
            ++count;
        }
    }
    return static_cast<std::int64_t>(required);
}

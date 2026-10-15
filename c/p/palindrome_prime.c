/* Encode the first n palindrome primes as little-endian u32 values. */
#include <stddef.h>
#include <stdint.h>

static int is_prime(uint32_t value)
{
    if (value < 2) return 0;
    for (uint32_t divisor = 2; divisor <= value / divisor; ++divisor)
        if (value % divisor == 0) return 0;
    return 1;
}

static uint32_t reverse_decimal(uint32_t value)
{
    uint32_t reversed = 0;
    while (value > 0) {
        reversed = reversed * 10 + value % 10;
        value /= 10;
    }
    return reversed;
}

static void write_u32_le(uint8_t *output, size_t position, uint32_t value)
{
    output[position] = (uint8_t)value;
    output[position + 1] = (uint8_t)(value >> 8);
    output[position + 2] = (uint8_t)(value >> 16);
    output[position + 3] = (uint8_t)(value >> 24);
}

int64_t palindrome_prime(int64_t n, uint8_t *output, size_t output_capacity)
{
    if (n > 16) return -1;
    if (n <= 0) return 0;
    const size_t required = (size_t)n * 4;
    if (output == NULL || output_capacity < required) return -2;

    write_u32_le(output, 0, 2);
    size_t count = 1;
    for (uint32_t candidate = 3; count < (size_t)n; candidate += 2) {
        if (candidate == reverse_decimal(candidate) && is_prime(candidate)) {
            write_u32_le(output, count * 4, candidate);
            ++count;
        }
    }
    return (int64_t)required;
}

// Encode ascending prime/exponent pairs as little-endian u32 values.
#include <cstddef>
#include <cstdint>

static std::size_t factor_pairs(std::int64_t value, std::uint32_t primes[10],
                                std::uint32_t exponents[10])
{
    if (value <= 1) { primes[0] = static_cast<std::uint32_t>(value); exponents[0] = 1; return 1; }
    std::size_t count = 0;
    auto remaining = value;
    for (std::int64_t divisor = 2; divisor <= remaining / divisor; ++divisor) {
        if (remaining % divisor == 0) {
            std::uint32_t exponent = 0;
            do { remaining /= divisor; ++exponent; } while (remaining % divisor == 0);
            primes[count] = static_cast<std::uint32_t>(divisor);
            exponents[count++] = exponent;
        }
    }
    if (remaining > 1) {
        primes[count] = static_cast<std::uint32_t>(remaining);
        exponents[count++] = 1;
    }
    return count;
}

static void write_u32le(std::uint32_t value, std::uint8_t *output)
{
    for (unsigned byte = 0; byte < 4; ++byte)
        output[byte] = static_cast<std::uint8_t>(value >> (8 * byte));
}

extern "C" std::int64_t factorize(std::int64_t value, std::uint8_t *output,
                                             std::size_t output_capacity)
{
    if (value < 0 || value > 1000005) return -1;
    std::uint32_t primes[10], exponents[10];
    const auto count = factor_pairs(value, primes, exponents);
    const auto required = count * 8;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t i = 0; i < count; ++i) {
        write_u32le(primes[i], output + 8 * i);
        write_u32le(exponents[i], output + 8 * i + 4);
    }
    return static_cast<std::int64_t>(required);
}

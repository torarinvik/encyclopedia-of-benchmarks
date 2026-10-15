// Sieve through n, then emit ascending prime/exponent pairs as little-endian u32 values.
#include <cstddef>
#include <cstdint>
#include <vector>

static void write_u32le(std::uint32_t value, std::uint8_t *output)
{
    for (unsigned byte = 0; byte < 4; ++byte)
        output[byte] = static_cast<std::uint8_t>(value >> (8 * byte));
}

extern "C" std::int64_t prime_factorization_sieve(std::int64_t value, std::uint8_t *output,
                                                   std::size_t output_capacity)
{
    if (value < 1 || value > 1'000'005) return -1;
    if (value == 1) return 0;
    const auto limit = static_cast<std::size_t>(value);
    std::vector<bool> is_prime(limit + 1, true);
    is_prime[0] = false;
    is_prime[1] = false;
    for (std::size_t prime = 2; prime <= limit / prime; ++prime) {
        if (!is_prime[prime]) continue;
        for (std::size_t multiple = prime * prime; multiple <= limit; multiple += prime)
            is_prime[multiple] = false;
    }

    std::uint32_t primes[10], exponents[10];
    std::size_t count = 0;
    auto remaining = value;
    for (std::size_t prime = 2; prime <= limit && remaining > 1; ++prime) {
        if (!is_prime[prime]) continue;
        std::uint32_t exponent = 0;
        while (remaining % static_cast<std::int64_t>(prime) == 0) {
            remaining /= static_cast<std::int64_t>(prime);
            ++exponent;
        }
        if (exponent != 0) {
            primes[count] = static_cast<std::uint32_t>(prime);
            exponents[count++] = exponent;
        }
    }
    const auto required = count * 8;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t index = 0; index < count; ++index) {
        write_u32le(primes[index], output + 8 * index);
        write_u32le(exponents[index], output + 8 * index + 4);
    }
    return static_cast<std::int64_t>(required);
}

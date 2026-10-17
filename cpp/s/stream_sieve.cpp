/* Extend and reuse one process-wide prime prefix, like the source LazyList. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_PRIMES = 100;
std::int32_t prime_cache[MAX_PRIMES] = {2};
std::size_t prime_count = 1;
std::int32_t next_candidate = 3;

bool is_prime_candidate(std::int32_t candidate)
{
    for (std::size_t index = 0; index < prime_count; ++index) {
        const std::int32_t divisor = prime_cache[index];
        if (divisor > candidate / divisor) break;
        if (candidate % divisor == 0) return false;
    }
    return true;
}

void extend_prime_cache(std::size_t requested_count)
{
    while (prime_count < requested_count) {
        const std::int32_t candidate = next_candidate;
        ++next_candidate;
        if (is_prime_candidate(candidate)) prime_cache[prime_count++] = candidate;
    }
}
} // namespace

extern "C" std::int64_t stream_sieve(std::int64_t number_of_primes,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (number_of_primes < -2147483648LL || number_of_primes > 100) return -1;
    if (number_of_primes <= 0) return 0;
    const std::size_t count = static_cast<std::size_t>(number_of_primes);
    const std::size_t required = count * 4;
    if (output == nullptr || output_capacity < required) return -2;

    extend_prime_cache(count);
    for (std::size_t index = 0; index < count; ++index) {
        const std::uint32_t bits = static_cast<std::uint32_t>(prime_cache[index]);
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[index * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(required);
}

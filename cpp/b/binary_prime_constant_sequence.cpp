/* Emit the prime characteristic sequence: 1 for primes and 0 otherwise. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_COUNT = 4096;

bool is_prime(std::int64_t candidate)
{
    if (candidate < 2) return false;
    for (std::int64_t divisor = 2; divisor <= candidate / divisor; ++divisor) {
        if (candidate % divisor == 0) return false;
    }
    return true;
}
}

extern "C" std::int64_t binary_prime_constant_sequence(const std::int64_t *input,
                                                        std::size_t length,
                                                        std::uint8_t *output,
                                                        std::size_t output_capacity) noexcept
{
    if (input == nullptr || length != 1 || input[0] < 0 || input[0] > MAX_COUNT) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (output_capacity < count || (count != 0 && output == nullptr)) return -2;

    std::size_t next = 1;
    for (std::int64_t candidate = 2; candidate <= input[0]; ++candidate) {
        if (!is_prime(candidate)) continue;
        while (next < static_cast<std::size_t>(candidate)) output[next++ - 1] = 0;
        output[static_cast<std::size_t>(candidate) - 1] = 1;
        next = static_cast<std::size_t>(candidate) + 1;
    }
    while (next <= count) output[next++ - 1] = 0;
    return static_cast<std::int64_t>(count);
}

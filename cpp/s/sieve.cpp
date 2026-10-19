#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t SIEVE_LIMIT = 8192;
constexpr std::int64_t MAX_ITERATIONS = 64;
constexpr char PREFIX[] = "Count: ";
}

extern "C" std::int64_t sieve(std::int64_t iterations, std::uint8_t *output,
    std::size_t output_capacity) noexcept
{
    if (iterations < 0 || iterations > MAX_ITERATIONS) return -1;

    std::uint8_t flags[SIEVE_LIMIT + 1];
    std::int64_t count = 0;
    for (std::int64_t pass = 0; pass < iterations; ++pass) {
        count = 0;
        for (std::int64_t value = 2; value <= SIEVE_LIMIT; ++value)
            flags[value] = 1;
        for (std::int64_t value = 2; value <= SIEVE_LIMIT; ++value) {
            if (flags[value]) {
                ++count;
                for (std::int64_t multiple = value + value; multiple <= SIEVE_LIMIT; multiple += value)
                    flags[multiple] = 0;
            }
        }
    }

    std::uint8_t reversed_digits[10];
    std::size_t digit_count = 0;
    std::int64_t remaining = count;
    do {
        reversed_digits[digit_count++] = static_cast<std::uint8_t>('0' + remaining % 10);
        remaining /= 10;
    } while (remaining != 0);
    const std::size_t required = sizeof(PREFIX) - 1 + digit_count + 1;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t index = 0; index < sizeof(PREFIX) - 1; ++index)
        output[index] = static_cast<std::uint8_t>(PREFIX[index]);
    for (std::size_t index = 0; index < digit_count; ++index)
        output[sizeof(PREFIX) - 1 + index] = reversed_digits[digit_count - index - 1];
    output[required - 1] = static_cast<std::uint8_t>('\n');
    return static_cast<std::int64_t>(required);
}

#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_input = 4096;
constexpr std::size_t max_distinct_factors = 5;

bool is_prime_by_source_trial_division(std::int64_t candidate)
{
    if (candidate == 2) return true;
    const std::int64_t half_candidate = candidate / 2 + 1;
    for (std::int64_t divisor = 2; divisor <= half_candidate; ++divisor) {
        if (candidate % divisor == 0) return false;
        if (divisor == half_candidate) return true;
    }
    return false;
}
}

extern "C" std::int64_t prime_factorial(std::int64_t value, std::uint8_t *output,
                                          std::size_t output_capacity)
{
    if (value < 2 || value > max_input) return -1;
    std::uint32_t factors[max_distinct_factors];
    std::size_t count = 0;
    for (std::int64_t candidate = 2; candidate <= value; ++candidate) {
        if (is_prime_by_source_trial_division(candidate) && value % candidate == 0) {
            factors[count++] = static_cast<std::uint32_t>(candidate);
        }
    }
    const std::size_t required = count * sizeof(std::uint32_t);
    if (output == nullptr || output_capacity < required) return -2;
    std::size_t position = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const std::uint32_t factor = factors[index];
        for (unsigned byte_index = 0; byte_index < 4; ++byte_index) {
            output[position++] = static_cast<std::uint8_t>(factor >> (8 * byte_index));
        }
    }
    return static_cast<std::int64_t>(position);
}

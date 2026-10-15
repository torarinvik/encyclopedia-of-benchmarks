/* Return the first source-ordered Goldbach pair as two little-endian i32 values. */
#include <cstddef>
#include <cstdint>

namespace {
bool is_prime(std::int64_t value) noexcept
{
    if (value == 2) return true;
    if (value < 2 || value % 2 == 0) return false;
    for (std::int64_t divisor = 3; divisor <= value / divisor; divisor += 2)
        if (value % divisor == 0) return false;
    return true;
}
}

extern "C" std::int64_t goldbach_conjecture(std::int64_t number, std::uint8_t *output,
                                               std::size_t output_capacity) noexcept
{
    if (number < 4 || number > 4096 || number % 2 != 0) return -1;
    if (output == nullptr || output_capacity < 8) return -2;
    for (std::int64_t first = 0; first <= number / 2; ++first) {
        const auto second = number - first;
        if (is_prime(first) && is_prime(second)) {
            const std::uint32_t pair[2] = {static_cast<std::uint32_t>(first), static_cast<std::uint32_t>(second)};
            for (std::size_t j = 0; j < 2; ++j)
                for (std::size_t b = 0; b < 4; ++b)
                    output[4 * j + b] = static_cast<std::uint8_t>((pair[j] >> (8 * b)) & 0xffU);
            return 8;
        }
    }
    return -1;
}

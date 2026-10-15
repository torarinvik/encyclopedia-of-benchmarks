/* Return the complementary DNA strand. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t dna(const std::int64_t *values, std::size_t length,
                            std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 1 || length > 1001 || values[0] != 0) return -1;
    const std::size_t count = length - 1;
    for (std::size_t index = 1; index < length; ++index) {
        const auto base = values[index];
        if (base != 'A' && base != 'T' && base != 'C' && base != 'G') return -1;
    }
    if (output_capacity < count || (count != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < count; ++index) {
        switch (values[index + 1]) {
        case 'A': output[index] = 'T'; break;
        case 'T': output[index] = 'A'; break;
        case 'C': output[index] = 'G'; break;
        default: output[index] = 'C'; break; // G
        }
    }
    return static_cast<std::int64_t>(count);
}

/* Replace thymine with uracil in an uppercase ASCII sequence. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t dna2_rna(const std::int64_t *values, std::size_t length,
                                 std::uint8_t *output,
                                 std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 1 || length > 1001 || values[0] != 0) return -1;
    const std::size_t count = length - 1;
    for (std::size_t index = 1; index < length; ++index)
        if (values[index] < 'A' || values[index] > 'Z') return -1;
    if (output_capacity < count || (count != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < count; ++index) {
        const auto base = values[index + 1];
        output[index] = static_cast<std::uint8_t>(base == 'T' ? 'U' : base);
    }
    return static_cast<std::int64_t>(count);
}

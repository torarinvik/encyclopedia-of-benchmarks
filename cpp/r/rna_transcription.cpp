/* Transcribe a DNA strand into its complementary RNA bases. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t rna_transcription(const std::int64_t *values, std::size_t length,
                                          std::uint8_t *output,
                                          std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 1 || length > 1001 || values[0] != 0) return -1;
    const std::size_t count = length - 1;
    for (std::size_t index = 1; index < length; ++index) {
        const auto base = values[index];
        if (base != 'A' && base != 'C' && base != 'G' && base != 'T') return -1;
    }
    if (output_capacity < count || (count != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < count; ++index) {
        switch (values[index + 1]) {
        case 'A': output[index] = 'U'; break;
        case 'C': output[index] = 'G'; break;
        case 'G': output[index] = 'C'; break;
        default: output[index] = 'A'; break; // T
        }
    }
    return static_cast<std::int64_t>(count);
}

/* Reverse a DNA sequence and complement each base. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxReverseComplementLength = 1000;
}

extern "C" std::int64_t reverse_complement(const std::int64_t *input, std::size_t length,
                                           std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > MaxReverseComplementLength || (length != 0 && input == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (input[i] != 'A' && input[i] != 'C' && input[i] != 'G' && input[i] != 'T') return -1;
    if (output_capacity < length || (length != 0 && output == nullptr)) return -2;
    for (std::size_t i = 0; i < length; ++i) {
        const auto base = input[length - 1 - i];
        output[i] = static_cast<std::uint8_t>(base == 'A' ? 'T' : base == 'T' ? 'A' : base == 'C' ? 'G' : 'C');
    }
    return static_cast<std::int64_t>(length);
}

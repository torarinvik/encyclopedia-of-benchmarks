#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_index = 4096;
constexpr std::int64_t max_count = 128;

void store_u64_le(std::uint8_t* output, std::size_t offset, std::uint64_t value) {
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(value >> (byte * 8));
}

void radical_inverse(std::int64_t index, std::int64_t base,
                     std::uint64_t& numerator, std::uint64_t& denominator) {
    std::uint64_t reversed = 0;
    std::uint64_t scale = 1;
    while (index > 0) {
        reversed = reversed * static_cast<std::uint64_t>(base)
                   + static_cast<std::uint64_t>(index % base);
        scale *= static_cast<std::uint64_t>(base);
        index /= base;
    }
    numerator = reversed;
    denominator = scale;
}
}

extern "C" std::int64_t van_der_corput_sequence(const std::int64_t* input,
                                                  std::size_t length,
                                                  std::uint8_t* output,
                                                  std::size_t capacity) noexcept {
    if (input == nullptr || length != 3) return -1;
    const std::int64_t base = input[0];
    const std::int64_t first_index = input[1];
    const std::int64_t count = input[2];
    if (base < 2 || base > 16 || first_index < 1 || first_index > max_index
        || count < 0 || count > max_count
        || (count > 0 && first_index + count - 1 > max_index)) return -1;

    const std::size_t output_bytes = static_cast<std::size_t>(count) * 16;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::int64_t offset = 0; offset < count; ++offset) {
        std::uint64_t numerator = 0;
        std::uint64_t denominator = 1;
        radical_inverse(first_index + offset, base, numerator, denominator);
        const auto position = static_cast<std::size_t>(offset) * 16;
        store_u64_le(output, position, numerator);
        store_u64_le(output, position + 8, denominator);
    }
    return static_cast<std::int64_t>(output_bytes);
}

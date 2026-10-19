/* Bounded port of BitBench five11's MSB-first packet decoder and channel sum. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input = 13523;
constexpr std::size_t max_parseable_input = 13524;
constexpr std::int64_t max_packets = 451;

std::int64_t read_bits(const std::int64_t *values, std::size_t length,
                       std::size_t bit_offset, unsigned width) {
    const std::size_t bit_length = length * 8;
    if (bit_offset > bit_length || width > bit_length - bit_offset) return -1;
    const std::size_t byte_offset = bit_offset >> 3;
    const unsigned start = static_cast<unsigned>(bit_offset & 7u);
    const std::size_t byte_count = (start + width + 7u) >> 3;
    std::uint32_t window = 0;
    for (std::size_t index = 0; index < byte_count; ++index)
        window = (window << 8) | static_cast<std::uint32_t>(values[byte_offset + index]);
    const unsigned shift = static_cast<unsigned>(byte_count * 8u) - start - width;
    const std::uint32_t mask = (std::uint32_t{1} << width) - 1u;
    return static_cast<std::int64_t>((window >> shift) & mask);
}

std::int64_t decode_sum(const std::int64_t *values, std::size_t length) {
    const std::int64_t packet_count = read_bits(values, length, 0, 16);
    if (packet_count < 0 || packet_count > max_packets) return -1;
    std::size_t bit_offset = 16;
    std::int64_t total = 0;
    for (std::int64_t packet = 0; packet < packet_count; ++packet) {
        const std::int64_t channels = read_bits(values, length, bit_offset, 5);
        if (channels < 0) return -1;
        bit_offset += 5;
        for (std::int64_t channel = 0; channel < channels; ++channel) {
            const std::int64_t value = read_bits(values, length, bit_offset, 11);
            if (value < 0) return -1;
            total += value;
            bit_offset += 11;
        }
        const std::size_t packet_bits = 5 + 11 * static_cast<std::size_t>(channels);
        bit_offset += (8 - (packet_bits & 7)) & 7;
        if (bit_offset > length * 8) return -1;
    }
    return total;
}
}

extern "C" std::int64_t five11(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 2 || length > max_parseable_input || length > max_input)
        return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 255) return -1;
    std::int64_t result = 0;
    for (int repetition = 0; repetition < 10000; ++repetition) {
        result = decode_sum(values, length);
        if (result < 0) return -1;
    }
    return result;
}

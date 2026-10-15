#include <cstddef>
#include <cstdint>

namespace {
constexpr char alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
bool edge_space(std::int64_t value) { return (value >= 9 && value <= 13) || value == 32; }
}

extern "C" std::int64_t binary_to_base64(const std::int64_t *input, std::size_t length,
                                           std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || input[0] < 1 || input[0] > 256) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    std::size_t begin = 0, end = n;
    while (begin < end && edge_space(input[1 + begin])) ++begin;
    while (end > begin && edge_space(input[end])) --end;
    if (begin == end) return -1;
    const bool negative = input[1 + begin] == '-';
    if (negative) ++begin;
    for (std::size_t i = begin; i < end; ++i) if (input[1 + i] != '0' && input[1 + i] != '1') return -1;
    const auto bit_count = end - begin;
    const auto padding = 6 - bit_count % 6;
    const auto groups = (bit_count + padding) / 6;
    const auto output_length = groups + (negative ? 1 : 0);
    if (capacity < output_length || output == nullptr) return -2;
    std::size_t offset = 0;
    if (negative) output[offset++] = '-';
    for (std::size_t group = 0; group < groups; ++group) {
        unsigned value = 0;
        for (std::size_t bit = 0; bit < 6; ++bit) {
            value <<= 1;
            const auto position = group * 6 + bit;
            if (position >= padding && input[1 + begin + position - padding] == '1') ++value;
        }
        output[offset++] = static_cast<std::uint8_t>(alphabet[value]);
    }
    return static_cast<std::int64_t>(output_length);
}

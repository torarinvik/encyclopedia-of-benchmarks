#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 64;
constexpr std::size_t max_input_length = 66;
constexpr std::size_t max_output_bytes = 1536;

void store_i64_le(std::array<std::uint8_t, max_output_bytes>& output,
                  std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t lz77_java_compress(const std::int64_t* input,
    std::size_t input_length, std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 1 || input_length > max_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_text_length)) return -1;
    const auto text_length = static_cast<std::size_t>(input[0]);
    if (input_length != 1 + text_length) return -1;
    for (std::size_t index = 0; index < text_length; ++index)
        if (input[index + 1] < 32 || input[index + 1] > 126) return -1;

    std::array<std::uint8_t, max_output_bytes> staged{};
    std::size_t token_count = 0;
    std::size_t current = 0;
    while (current < text_length) {
        std::size_t best_distance = 0;
        std::size_t best_length = 0;
        const std::size_t search_start = current > 4096 ? current - 4096 : 0;
        const std::size_t lookahead_end = std::min(current + 16, text_length);
        for (std::size_t candidate = search_start; candidate < current; ++candidate) {
            std::size_t match_length = 0;
            while (current + match_length < lookahead_end) {
                std::size_t source = candidate + match_length;
                if (source >= current) {
                    const std::size_t distance = current - candidate;
                    source = candidate + (match_length % distance);
                }
                if (input[source + 1] != input[current + match_length + 1]) break;
                ++match_length;
            }
            if (match_length > best_length) {
                best_distance = current - candidate;
                best_length = match_length;
            }
        }
        const std::int64_t next_character = current + best_length < text_length
            ? input[current + best_length + 1] : 0;
        const std::size_t byte_offset = token_count * 24;
        store_i64_le(staged, byte_offset, static_cast<std::int64_t>(best_distance));
        store_i64_le(staged, byte_offset + 8, static_cast<std::int64_t>(best_length));
        store_i64_le(staged, byte_offset + 16, next_character);
        ++token_count;
        current += next_character == 0 ? best_length : best_length + 1;
    }

    const std::size_t output_bytes = token_count * 24;
    if (output_bytes > max_output_bytes) return -1;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_bytes);
}

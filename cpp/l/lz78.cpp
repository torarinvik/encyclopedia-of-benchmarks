/* Compress a bounded printable-ASCII string using LZ78 phrase tokens. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 64;
constexpr std::size_t max_parseable_input_length = 66;
constexpr std::size_t max_nodes = max_input_length + 1;
constexpr std::size_t alphabet_size = 95;
constexpr std::size_t max_output_bytes = 1024;

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t lz78_compress(const std::int64_t* input, std::size_t input_length,
                                      std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 1 || input_length > max_parseable_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_input_length)) return -1;
    const auto character_count = static_cast<std::size_t>(input[0]);
    if (input_length != 1 + character_count) return -1;
    for (std::size_t index = 0; index < character_count; ++index)
        if (input[index + 1] < 32 || input[index + 1] > 126) return -1;

    // Child id zero means absent; created nodes and phrase indices start at one.
    std::array<std::array<std::size_t, alphabet_size>, max_nodes> children{};
    std::array<std::int64_t, max_input_length> token_prefix{};
    std::array<std::int64_t, max_input_length> token_character{};
    std::size_t node_count = 1;
    std::size_t current_node = 0;
    std::size_t last_matched_index = 0;
    std::size_t token_count = 0;

    for (std::size_t index = 0; index < character_count; ++index) {
        const auto character = input[index + 1];
        const auto edge = static_cast<std::size_t>(character - 32);
        const auto child = children[current_node][edge];
        if (child != 0) {
            current_node = child;
            last_matched_index = child;
        } else {
            token_prefix[token_count] = static_cast<std::int64_t>(last_matched_index);
            token_character[token_count] = character;
            ++token_count;
            children[current_node][edge] = node_count++;
            current_node = 0;
            last_matched_index = 0;
        }
    }

    if (current_node != 0) {
        token_prefix[token_count] = static_cast<std::int64_t>(last_matched_index);
        token_character[token_count] = 0;
        ++token_count;
    }

    const std::size_t output_bytes = 16 * token_count;
    if (output_bytes > max_output_bytes) return -1;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t token = 0; token < token_count; ++token) {
        store_i64_le(output, 16 * token, token_prefix[token]);
        store_i64_le(output, 16 * token + 8, token_character[token]);
    }
    return static_cast<std::int64_t>(output_bytes);
}

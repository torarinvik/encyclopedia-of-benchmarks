/* Clean-room bounded Kosaraju-Manzini LZ78RL profile. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 32;
constexpr std::size_t max_parseable_input_length = 34;
constexpr std::size_t max_trie_nodes = 33;
constexpr std::size_t max_tokens = 32;
constexpr std::size_t alphabet_size = 4;
constexpr std::size_t max_output_bytes = 776;

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t lz78_run_length_transform(const std::int64_t* input,
        std::size_t input_length, std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 1 || input_length > max_parseable_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_text_length)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (input_length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 1] < 1 || input[i + 1] > 3) return -1;

    std::array<std::int64_t, max_text_length> transformed{};
    std::size_t transformed_length = 0;
    std::size_t position = 0;
    while (position < n) {
        const auto symbol = input[position + 1];
        std::size_t end = position + 1;
        while (end < n && input[end + 1] == symbol) ++end;
        const auto run_length = end - position;
        std::size_t highest_bit = 0;
        for (auto value = run_length; value > 1; value >>= 1) ++highest_bit;
        for (std::size_t bit = highest_bit + 1; bit > 0; --bit) {
            const auto shift = bit - 1;
            transformed[transformed_length++] = ((run_length >> shift) & 1) ? symbol : 0;
        }
        position = end;
    }

    std::array<std::array<std::size_t, alphabet_size>, max_trie_nodes> children{};
    std::array<std::array<std::int64_t, 3>, max_tokens> tokens{};
    std::size_t token_count = 0;
    std::size_t text_position = 0;
    std::size_t next_phrase_id = 1;
    while (text_position < transformed_length) {
        std::size_t node = 0;
        std::size_t end = text_position;
        while (end < transformed_length) {
            const auto child = children[node][static_cast<std::size_t>(transformed[end])];
            if (child == 0) break;
            node = child;
            ++end;
        }
        if (end == transformed_length) {
            if (node != 0) tokens[token_count++] = {static_cast<std::int64_t>(node), 0, 1};
            break;
        }
        const auto symbol = static_cast<std::size_t>(transformed[end]);
        tokens[token_count++] = {static_cast<std::int64_t>(node), static_cast<std::int64_t>(symbol), 0};
        children[node][symbol] = next_phrase_id++;
        text_position = end + 1;
    }

    const auto output_bytes = 8 + 24 * token_count;
    std::array<std::uint8_t, max_output_bytes> staged{};
    store_i64_le(staged.data(), 0, static_cast<std::int64_t>(token_count));
    for (std::size_t token = 0; token < token_count; ++token)
        for (std::size_t field = 0; field < 3; ++field)
            store_i64_le(staged.data(), 8 + 24 * token + 8 * field, tokens[token][field]);
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(output_bytes);
}

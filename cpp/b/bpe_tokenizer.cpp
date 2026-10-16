/* Apply bounded byte-pair merges with first-seen tie-breaking. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t bpe_tokenizer(const std::int64_t *values, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 2 || length > 515) return -2;
    const auto merge_count_value = values[0];
    const auto byte_count_value = values[1];
    if (merge_count_value < 0 || merge_count_value > 32 || byte_count_value < 0
        || byte_count_value > 512 || length != static_cast<std::size_t>(byte_count_value) + 2) return -2;

    std::int64_t tokens[512]{};
    std::int64_t next_tokens[512]{};
    const auto byte_count = static_cast<std::size_t>(byte_count_value);
    for (std::size_t index = 0; index < byte_count; ++index) {
        if (values[index + 2] < 0 || values[index + 2] > 255) return -2;
        tokens[index] = values[index + 2];
    }
    auto token_count = byte_count;
    for (std::size_t step = 0; step < static_cast<std::size_t>(merge_count_value) && token_count > 1; ++step) {
        std::int64_t pair_left[511]{};
        std::int64_t pair_right[511]{};
        std::int64_t pair_frequency[511]{};
        std::size_t unique_pairs = 0;
        for (std::size_t index = 0; index + 1 < token_count; ++index) {
            auto pair_index = std::size_t{0};
            while (pair_index < unique_pairs
                   && (pair_left[pair_index] != tokens[index] || pair_right[pair_index] != tokens[index + 1])) ++pair_index;
            if (pair_index == unique_pairs) {
                pair_left[pair_index] = tokens[index];
                pair_right[pair_index] = tokens[index + 1];
                pair_frequency[pair_index] = 1;
                ++unique_pairs;
            } else {
                ++pair_frequency[pair_index];
            }
        }
        if (unique_pairs == 0) break;
        auto best = std::size_t{0};
        for (std::size_t index = 1; index < unique_pairs; ++index)
            if (pair_frequency[index] > pair_frequency[best]) best = index;
        if (pair_frequency[best] == 1) break;

        std::size_t next_count = 0;
        auto index = std::size_t{0};
        while (index < token_count) {
            if (index + 1 < token_count && tokens[index] == pair_left[best]
                && tokens[index + 1] == pair_right[best]) {
                next_tokens[next_count++] = 256 + static_cast<std::int64_t>(step);
                index += 2;
            } else {
                next_tokens[next_count++] = tokens[index++];
            }
        }
        for (std::size_t item = 0; item < next_count; ++item) tokens[item] = next_tokens[item];
        token_count = next_count;
    }
    if (token_count > output_capacity / 2 || (token_count != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < token_count; ++index) {
        const auto token = static_cast<std::uint16_t>(tokens[index]);
        output[2 * index] = static_cast<std::uint8_t>(token & 0xff);
        output[2 * index + 1] = static_cast<std::uint8_t>(token >> 8);
    }
    return static_cast<std::int64_t>(token_count);
}

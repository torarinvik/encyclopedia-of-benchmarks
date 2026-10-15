// Count literal-space-delimited words and matches for one requested word.
#include <cstddef>
#include <cstdint>

static void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

extern "C" std::int64_t word_count(const std::int64_t *values, std::size_t length,
        std::uint8_t *output, std::size_t output_capacity)
{
    if (values == nullptr || length < 2 || length > 1050) return -1;
    if (values[0] < 0 || values[0] > 999) return -1;
    const auto text_length = static_cast<std::size_t>(values[0]);
    const auto query_index = 1 + text_length;
    if (query_index >= length || values[query_index] < 0 || values[query_index] > 49) return -1;
    const auto query_length = static_cast<std::size_t>(values[query_index]);
    if (length != query_index + 1 + query_length) return -1;
    for (std::size_t i = 1; i < query_index; ++i) if (values[i] < 1 || values[i] > 127) return -1;
    for (std::size_t i = query_index + 1; i < length; ++i) if (values[i] < 1 || values[i] > 127) return -1;
    std::size_t total = 0, matches = 0, start = 0;
    for (std::size_t end = 0; end <= text_length; ++end) {
        if (end == text_length || values[1 + end] == 32) {
            const auto token_length = end - start;
            if (token_length > 49) return -1;
            if (total >= 20) return -2;
            if (token_length == query_length) {
                std::size_t offset = 0;
                while (offset < token_length && values[1 + start + offset] == values[query_index + 1 + offset]) ++offset;
                if (offset == token_length) ++matches;
            }
            ++total;
            start = end + 1;
        }
    }
    if (output == nullptr || output_capacity < 16) return -2;
    store_i64_le(output, 0, static_cast<std::int64_t>(total));
    store_i64_le(output, 8, static_cast<std::int64_t>(matches));
    return 16;
}

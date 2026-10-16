/* Sort bounded decimal strings by the pinned length/lexicographic comparator. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 64;
constexpr std::size_t max_token_length = 32;
constexpr std::size_t max_input_length = 2113;
constexpr std::size_t max_output_length = max_items * max_token_length + max_items - 1;

struct TokenRef {
    std::size_t start;
    std::size_t length;
    std::size_t normalized_start;
    std::size_t normalized_length;
};

bool token_less(const std::int64_t *values, const TokenRef &left, const TokenRef &right) noexcept
{
    if (left.normalized_length != right.normalized_length)
        return left.normalized_length < right.normalized_length;
    for (std::size_t i = 0; i < left.normalized_length; ++i) {
        const auto a = values[left.normalized_start + i];
        const auto b = values[right.normalized_start + i];
        if (a != b) return a < b;
    }
    return false;
}
}

extern "C" std::int64_t numeric_string_sort(const std::int64_t *values, std::size_t length,
                                             std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length == 0 || length > max_input_length + 1) return -1;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(max_items)) return -1;
    const auto count = static_cast<std::size_t>(values[0]);
    std::array<TokenRef, max_items> tokens{};
    std::array<std::size_t, max_items> order{};
    std::size_t cursor = 1;
    std::size_t output_length = count == 0 ? 0 : count - 1;

    for (std::size_t i = 0; i < count; ++i) {
        if (cursor >= length) return -1;
        const auto raw_length = values[cursor++];
        if (raw_length < 1 || raw_length > static_cast<std::int64_t>(max_token_length) ||
            static_cast<std::size_t>(raw_length) > length - cursor) return -1;
        const auto token_length = static_cast<std::size_t>(raw_length);
        const auto start = cursor;
        for (std::size_t j = 0; j < token_length; ++j)
            if (values[start + j] < '0' || values[start + j] > '9') return -1;
        std::size_t zeros = 0;
        while (zeros < token_length && values[start + zeros] == '0') ++zeros;
        tokens[i] = {start, token_length, start + zeros, token_length - zeros};

        for (std::size_t j = 0; j < i; ++j) {
            const auto &previous = tokens[j];
            const auto &current = tokens[i];
            if (previous.normalized_length != current.normalized_length) continue;
            std::size_t k = 0;
            while (k < current.normalized_length &&
                   values[previous.normalized_start + k] == values[current.normalized_start + k]) ++k;
            if (k == current.normalized_length && previous.length != token_length) return -1;
            if (k == current.normalized_length && previous.length == token_length) {
                std::size_t raw = 0;
                while (raw < token_length && values[previous.start + raw] == values[start + raw]) ++raw;
                if (raw != token_length) return -1;
            }
        }
        output_length += token_length;
        cursor += token_length;
        order[i] = i;
    }
    if (cursor != length || output_length > max_output_length) return -1;

    for (std::size_t i = 1; i < count; ++i) {
        const auto key = order[i];
        auto position = i;
        while (position > 0 && token_less(values, tokens[key], tokens[order[position - 1]])) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = key;
    }
    if ((output == nullptr && output_length != 0) || output_capacity < output_length) return -2;
    std::size_t written = 0;
    for (std::size_t i = 0; i < count; ++i) {
        if (i != 0) output[written++] = static_cast<std::uint8_t>(' ');
        const auto &token = tokens[order[i]];
        for (std::size_t j = 0; j < token.length; ++j)
            output[written++] = static_cast<std::uint8_t>(values[token.start + j]);
    }
    return static_cast<std::int64_t>(output_length);
}

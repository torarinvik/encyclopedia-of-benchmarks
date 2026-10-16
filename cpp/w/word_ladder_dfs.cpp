#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_WORDS = 8;
constexpr std::size_t MAX_PATH_WORDS = MAX_WORDS + 1;
constexpr std::size_t MAX_INPUT_LENGTH = 4 + MAX_WORDS;
constexpr std::size_t MAX_OUTPUT_BYTES = 8 * (MAX_PATH_WORDS + MAX_WORDS + 2);

std::int64_t power_of_26(std::size_t exponent) {
    std::int64_t result = 1;
    for (std::size_t i = 0; i < exponent; ++i) result *= 26;
    return result;
}

std::size_t find_active_word(const std::int64_t* words, const bool* active,
                             std::size_t count, std::int64_t candidate) {
    for (std::size_t index = 0; index < count; ++index)
        if (active[index] && words[index] == candidate) return index;
    return count;
}

bool backtrack(std::int64_t current, std::int64_t end, std::size_t width,
               const std::int64_t* words, std::size_t count, bool* active,
               std::int64_t* path, std::size_t& path_length) {
    if (current == end) return true;
    for (std::size_t position = 0; position < width; ++position) {
        const std::int64_t factor = power_of_26(width - position - 1);
        const std::int64_t digit = (current / factor) % 26;
        for (std::int64_t replacement = 0; replacement < 26; ++replacement) {
            const std::int64_t candidate = current + (replacement - digit) * factor;
            const std::size_t index = find_active_word(words, active, count, candidate);
            if (index == count) continue;
            active[index] = false;
            path[path_length++] = candidate;
            if (backtrack(candidate, end, width, words, count, active, path, path_length)) return true;
            --path_length;
            active[index] = true;
        }
    }
    return false;
}

void write_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t word_ladder_dfs(const std::int64_t* input, std::size_t length,
                                           std::uint8_t* output, std::size_t output_capacity) {
    if (input == nullptr || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const std::int64_t width_value = input[0], begin = input[1], end = input[2], count_value = input[3];
    if (width_value < 1 || width_value > 5 || count_value < 0 || count_value > static_cast<std::int64_t>(MAX_WORDS) ||
        length != 4 + static_cast<std::size_t>(count_value)) return -1;
    const std::size_t width = static_cast<std::size_t>(width_value), count = static_cast<std::size_t>(count_value);
    const std::int64_t limit = power_of_26(width);
    if (begin < 0 || begin >= limit || end < 0 || end >= limit) return -1;
    const std::int64_t* words = input + 4;
    for (std::size_t index = 0; index < count; ++index)
        if (words[index] < 0 || words[index] >= limit || (index > 0 && words[index - 1] >= words[index])) return -1;

    bool active[MAX_WORDS] = {};
    for (std::size_t index = 0; index < count; ++index) active[index] = true;
    std::int64_t path[MAX_PATH_WORDS] = {};
    std::size_t path_length = 1;
    path[0] = begin;
    if (find_active_word(words, active, count, end) != count) {
        if (!backtrack(begin, end, width, words, count, active, path, path_length))
            path_length = 0;
    } else path_length = 0;

    std::int64_t scratch[MAX_PATH_WORDS + MAX_WORDS + 2];
    std::size_t fields = 0;
    scratch[fields++] = static_cast<std::int64_t>(path_length);
    for (std::size_t index = 0; index < path_length; ++index) scratch[fields++] = path[index];
    std::size_t remaining_count = 0;
    for (std::size_t index = 0; index < count; ++index) if (active[index]) ++remaining_count;
    scratch[fields++] = static_cast<std::int64_t>(remaining_count);
    for (std::size_t index = 0; index < count; ++index) if (active[index]) scratch[fields++] = words[index];
    const std::size_t required = fields * 8;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t index = 0; index < fields; ++index) write_i64_le(output, index * 8, scratch[index]);
    return static_cast<std::int64_t>(required);
}

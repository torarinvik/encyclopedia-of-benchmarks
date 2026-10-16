/* Count bounded ASCII tokens in insertion order, matching the pinned Java routine. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input = 256;
constexpr std::size_t max_words = 128;
constexpr std::size_t table_size = 512;

bool is_space_byte(std::int64_t value) noexcept {
    return value == 9 || value == 10 || value == 11 || value == 12 || value == 13 || value == 32;
}

std::size_t token_hash(const std::int64_t* input, std::size_t start, std::size_t length) noexcept {
    std::size_t hash = 0;
    for (std::size_t offset = 0; offset < length; ++offset)
        hash = (hash * 31 + static_cast<std::size_t>(input[start + offset])) % 1000003;
    return hash;
}

bool token_equal(const std::int64_t* input, std::size_t start, std::size_t length,
                 std::size_t other_start, std::size_t other_length) noexcept {
    if (length != other_length) return false;
    for (std::size_t offset = 0; offset < length; ++offset)
        if (input[start + offset] != input[other_start + offset]) return false;
    return true;
}

std::size_t write_count(std::uint8_t* output, std::size_t position, std::size_t count) noexcept {
    std::uint8_t digits[3];
    std::size_t digit_count = 0;
    do {
        digits[digit_count++] = static_cast<std::uint8_t>('0' + count % 10);
        count /= 10;
    } while (count != 0);
    while (digit_count != 0) output[position++] = digits[--digit_count];
    return position;
}
}

extern "C" std::int64_t map_reduce(const std::int64_t* input, std::size_t length,
                                    std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (length > max_input || (length != 0 && input == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = input[index];
        if (!is_space_byte(value) && (value < 32 || value > 126)) return -1;
    }

    std::size_t starts[max_words], lengths[max_words], counts[max_words]{};
    std::size_t table[table_size]{};
    std::size_t unique_count = 0, begin = 0, end = length;
    while (begin < end && input[begin] <= 32) ++begin;
    while (end > begin && input[end - 1] <= 32) --end;

    if (begin == end) {
        starts[0] = 0; lengths[0] = 0; counts[0] = 1; unique_count = 1;
        table[0] = 1;
    } else {
        std::size_t cursor = begin;
        while (cursor < end) {
            while (cursor < end && is_space_byte(input[cursor])) ++cursor;
            if (cursor == end) break;
            const std::size_t start = cursor;
            while (cursor < end && !is_space_byte(input[cursor])) ++cursor;
            const std::size_t token_length = cursor - start;
            std::size_t slot = token_hash(input, start, token_length) % table_size;
            while (table[slot] != 0) {
                const std::size_t item = table[slot] - 1;
                if (token_equal(input, start, token_length, starts[item], lengths[item])) {
                    ++counts[item];
                    break;
                }
                slot = (slot + 1) % table_size;
            }
            if (table[slot] == 0) {
                starts[unique_count] = start;
                lengths[unique_count] = token_length;
                counts[unique_count] = 1;
                table[slot] = unique_count + 1;
                ++unique_count;
            }
        }
    }

    std::size_t required = 0;
    for (std::size_t item = 0; item < unique_count; ++item) {
        std::size_t digits = 1, value = counts[item];
        while (value >= 10) { value /= 10; ++digits; }
        required += lengths[item] + 2 + digits + (item != 0 ? 1 : 0);
    }
    if (output == nullptr || output_capacity < required) return -2;

    std::size_t written = 0;
    for (std::size_t item = 0; item < unique_count; ++item) {
        if (item != 0) output[written++] = ',';
        for (std::size_t offset = 0; offset < lengths[item]; ++offset)
            output[written++] = static_cast<std::uint8_t>(input[starts[item] + offset]);
        output[written++] = ':';
        output[written++] = ' ';
        written = write_count(output, written, counts[item]);
    }
    return static_cast<std::int64_t>(written);
}

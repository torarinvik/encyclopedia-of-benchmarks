#include <cstddef>
#include <cstdint>

namespace {
int compare_words(const std::int64_t *values, std::size_t start_a, std::size_t length_a,
                  std::size_t start_b, std::size_t length_b) {
    const std::size_t common = length_a < length_b ? length_a : length_b;
    for (std::size_t index = 0; index < common; ++index) {
        const auto a = values[1 + start_a + index];
        const auto b = values[1 + start_b + index];
        if (a != b) return a < b ? -1 : 1;
    }
    return (length_a > length_b) - (length_a < length_b);
}
}

extern "C" std::int64_t remove_duplicate(const std::int64_t *values, std::size_t length,
                                         std::uint8_t *output, std::size_t output_capacity) {
    if (values == nullptr || length < 1 || values[0] < 0 || values[0] > 1024 ||
        length != 1 + static_cast<std::size_t>(values[0])) return -1;
    const auto text_length = static_cast<std::size_t>(values[0]);
    for (std::size_t index = 0; index < text_length; ++index) {
        const auto byte = values[index + 1];
        if (byte != 32 && (byte < 'a' || byte > 'z')) return -1;
    }
    std::size_t starts[512], lengths[512], word_count = 0, cursor = 0;
    while (cursor < text_length) {
        if (values[cursor + 1] == 32) { ++cursor; continue; }
        starts[word_count] = cursor;
        while (cursor < text_length && values[cursor + 1] != 32) ++cursor;
        lengths[word_count] = cursor - starts[word_count];
        ++word_count;
    }
    for (std::size_t index = 1; index < word_count; ++index) {
        const auto key_start = starts[index];
        const auto key_length = lengths[index];
        std::size_t position = index;
        while (position > 0 && compare_words(values, starts[position - 1], lengths[position - 1],
                                             key_start, key_length) > 0) {
            starts[position] = starts[position - 1];
            lengths[position] = lengths[position - 1];
            --position;
        }
        starts[position] = key_start;
        lengths[position] = key_length;
    }
    std::size_t output_length = 0, unique_count = 0;
    for (std::size_t index = 0; index < word_count; ++index) {
        if (index > 0 && compare_words(values, starts[index - 1], lengths[index - 1],
                                       starts[index], lengths[index]) == 0) continue;
        if (unique_count > 0) ++output_length;
        output_length += lengths[index];
        ++unique_count;
    }
    if (output_length > output_capacity || (output_length > 0 && output == nullptr)) return -2;
    std::size_t written = 0, emitted = 0;
    for (std::size_t index = 0; index < word_count; ++index) {
        if (index > 0 && compare_words(values, starts[index - 1], lengths[index - 1],
                                       starts[index], lengths[index]) == 0) continue;
        if (emitted++ > 0) output[written++] = ' ';
        for (std::size_t byte = 0; byte < lengths[index]; ++byte)
            output[written++] = static_cast<std::uint8_t>(values[1 + starts[index] + byte]);
    }
    return static_cast<std::int64_t>(output_length);
}

#include <cstddef>
#include <cstdint>

static bool contains_character(std::int64_t value, const std::int64_t *input,
                               std::size_t set_start, std::int64_t set_length) noexcept {
    if (set_length == -1) return value == 9 || value == 10 || value == 13 || value == 32;
    for (std::size_t i = 0; i < static_cast<std::size_t>(set_length); ++i)
        if (input[set_start + i] == value) return true;
    return false;
}

extern "C" std::int64_t strip(const std::int64_t *input, std::size_t length,
                               std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > 386) return -1;
    if (input[0] < 0 || input[0] > 256) return -1;
    const std::size_t text_length = static_cast<std::size_t>(input[0]);
    const std::size_t set_index = 1 + text_length;
    if (set_index >= length) return -1;
    const std::int64_t set_length = input[set_index];
    std::size_t expected_length;
    if (set_length == -1) expected_length = set_index + 1;
    else {
        if (set_length < 0 || set_length > 128) return -1;
        expected_length = set_index + 1 + static_cast<std::size_t>(set_length);
    }
    if (length != expected_length) return -1;
    for (std::size_t i = 0; i < text_length; ++i)
        if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    if (set_length >= 0)
        for (std::size_t i = 0; i < static_cast<std::size_t>(set_length); ++i)
            if (input[set_index + 1 + i] < 0 || input[set_index + 1 + i] > 127) return -1;

    std::size_t start = 0, end = text_length;
    while (start < end && contains_character(input[1 + start], input,
                                               set_index + 1, set_length)) ++start;
    while (end > start && contains_character(input[end], input,
                                               set_index + 1, set_length)) --end;
    const std::size_t output_length = end - start;
    if (output_capacity < output_length || (output_length > 0 && output == nullptr)) return -2;
    for (std::size_t i = 0; i < output_length; ++i)
        output[i] = static_cast<std::uint8_t>(input[1 + start + i]);
    return static_cast<std::int64_t>(output_length);
}

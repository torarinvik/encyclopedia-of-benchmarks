#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_keys = 4;
constexpr std::size_t max_key_length = 4;
constexpr std::size_t max_text_length = 64;
constexpr std::size_t max_input_length = 107;
constexpr std::size_t max_output_length = 256;

bool printable_ascii(std::int64_t value) { return value >= 32 && value <= 126; }
}

extern "C" std::int64_t translator(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_keys) || input[1] < 0 || input[1] > static_cast<std::int64_t>(max_text_length)) return -1;
    const auto key_count = static_cast<std::size_t>(input[0]);
    const auto text_length = static_cast<std::size_t>(input[1]);
    std::array<std::array<std::uint8_t, max_key_length>, max_keys> keys{};
    std::array<std::array<std::uint8_t, max_key_length>, max_keys> values{};
    std::array<std::size_t, max_keys> key_lengths{}, value_lengths{};
    std::size_t cursor = 2;
    for (std::size_t key_index = 0; key_index < key_count; ++key_index) {
        if (cursor + 2 > length) return -1;
        const auto key_length_value = input[cursor++];
        const auto value_length_value = input[cursor++];
        if (key_length_value < 1 || key_length_value > 4 || value_length_value < 0 || value_length_value > 4) return -1;
        const auto key_length = static_cast<std::size_t>(key_length_value);
        const auto value_length = static_cast<std::size_t>(value_length_value);
        if (cursor + key_length + value_length > length) return -1;
        for (std::size_t index = 0; index < key_length; ++index) {
            if (!printable_ascii(input[cursor + index])) return -1;
            keys[key_index][index] = static_cast<std::uint8_t>(input[cursor + index]);
        }
        cursor += key_length;
        for (std::size_t index = 0; index < value_length; ++index) {
            if (!printable_ascii(input[cursor + index])) return -1;
            values[key_index][index] = static_cast<std::uint8_t>(input[cursor + index]);
        }
        cursor += value_length;
        key_lengths[key_index] = key_length;
        value_lengths[key_index] = value_length;
        for (std::size_t previous = 0; previous < key_index; ++previous)
            if (key_lengths[previous] == key_length && std::memcmp(keys[previous].data(), keys[key_index].data(), key_length) == 0) return -1;
    }
    if (cursor + text_length != length) return -1;
    std::array<std::uint8_t, max_text_length> text{};
    for (std::size_t index = 0; index < text_length; ++index) {
        if (!printable_ascii(input[cursor + index])) return -1;
        text[index] = static_cast<std::uint8_t>(input[cursor + index]);
    }

    std::array<std::uint8_t, max_output_length> result{};
    std::size_t result_length = 0, start = 0;
    while (start < text_length) {
        bool matched = false;
        const auto maximum_length = std::min(max_key_length, text_length - start);
        for (std::size_t candidate_length = 1; candidate_length <= maximum_length && !matched; ++candidate_length) {
            for (std::size_t key_index = 0; key_index < key_count; ++key_index) {
                if (key_lengths[key_index] != candidate_length || std::memcmp(text.data() + start, keys[key_index].data(), candidate_length) != 0) continue;
                std::memcpy(result.data() + result_length, values[key_index].data(), value_lengths[key_index]);
                result_length += value_lengths[key_index];
                start += candidate_length;
                matched = true;
                break;
            }
        }
        if (!matched) break;
    }
    if (output == nullptr || capacity < result_length) return -2;
    if (result_length != 0) std::memcpy(output, result.data(), result_length);
    return static_cast<std::int64_t>(result_length);
}

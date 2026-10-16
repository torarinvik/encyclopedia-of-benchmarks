#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 1024;
constexpr std::size_t max_input_length = max_text_length + 3;
bool is_space(std::int64_t value) {
    return value == 32 || (value >= 9 && value <= 13) || (value >= 28 && value <= 31);
}
bool is_word(std::int64_t value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') ||
           (value >= '0' && value <= '9');
}
}

extern "C" std::int64_t string_switch_case(const std::int64_t *input, std::size_t length,
                                           std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input_length) return -1;
    const auto mode = input[0], separator = input[1], text_length = input[2];
    if (mode < 0 || mode > 8 || separator < 0 || separator > 127 || text_length < 0 ||
        text_length > static_cast<std::int64_t>(max_text_length) ||
        length != static_cast<std::size_t>(text_length) + 3 ||
        ((mode != 3 && mode != 4) && separator != 0)) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(text_length); ++i)
        if (input[i + 3] < 0 || input[i + 3] > 127) return -1;

    std::uint8_t result[max_text_length];
    std::size_t used = 0;
    if (mode <= 2) {
        bool at_word_start = true;
        for (std::size_t i = 0; i < static_cast<std::size_t>(text_length); ++i) {
            auto value = input[i + 3];
            if (!is_word(value)) { at_word_start = true; continue; }
            if (at_word_start) {
                if (value >= 'a' && value <= 'z') value -= 32;
                at_word_start = false;
            } else if (value >= 'A' && value <= 'Z') value += 32;
            result[used++] = static_cast<std::uint8_t>(value);
        }
        if (mode == 2) {
            if (used == 0) {
                constexpr char empty_message[] = "not valid string";
                for (std::size_t i = 0; i < sizeof(empty_message) - 1; ++i)
                    result[used++] = static_cast<std::uint8_t>(empty_message[i]);
            } else if (result[0] >= 'A' && result[0] <= 'Z') result[0] += 32;
        }
    } else {
        const bool upper = mode == 4 || mode == 6 || mode == 8;
        const auto delimiter = static_cast<std::uint8_t>(mode <= 4 ? separator : mode <= 6 ? '_' : '-');
        bool group_has_word = false, pending_space = false;
        for (std::size_t i = 0; i < static_cast<std::size_t>(text_length); ++i) {
            auto value = input[i + 3];
            if (is_space(value)) { if (group_has_word) pending_space = true; continue; }
            if (!is_word(value)) { group_has_word = false; pending_space = false; continue; }
            if (pending_space && group_has_word) result[used++] = delimiter;
            pending_space = false;
            if (upper && value >= 'a' && value <= 'z') value -= 32;
            else if (!upper && value >= 'A' && value <= 'Z') value += 32;
            result[used++] = static_cast<std::uint8_t>(value);
            group_has_word = true;
        }
    }
    if (used > capacity || (used != 0 && output == nullptr)) return -2;
    for (std::size_t i = 0; i < used; ++i) output[i] = result[i];
    return static_cast<std::int64_t>(used);
}

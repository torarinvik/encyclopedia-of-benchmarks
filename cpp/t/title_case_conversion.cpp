#include <cstddef>
#include <cstdint>

extern "C" std::int64_t title_case_conversion(const std::int64_t* input, std::size_t length,
                                               std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || input[0] < 0 || input[0] > 256) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t value = input[i + 1];
        if ((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z')) continue;
        if (value == ' ' && i > 0 && i + 1 < n && input[i] != ' ') continue;
        return -1;
    }
    if (output == nullptr || capacity < n + 1) return -2;
    bool at_word_start = true;
    for (std::size_t i = 0; i < n; ++i) {
        std::int64_t value = input[i + 1];
        if (value == ' ') {
            output[i] = static_cast<std::uint8_t>(value);
            at_word_start = true;
        } else if (at_word_start) {
            if (value >= 'a' && value <= 'z') value -= 'a' - 'A';
            output[i] = static_cast<std::uint8_t>(value);
            at_word_start = false;
        } else {
            if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
            output[i] = static_cast<std::uint8_t>(value);
        }
    }
    output[n] = 0;
    return static_cast<std::int64_t>(n);
}

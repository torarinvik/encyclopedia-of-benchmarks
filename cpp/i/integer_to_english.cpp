#include <cstddef>
#include <cstdint>

namespace {
constexpr const char* small[21] = {
    "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
    "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
    "Seventeen", "Eighteen", "Nineteen", "Twenty"
};
constexpr const char* tens[10] = {"", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"};
constexpr const char* scales[4] = {"", "Thousand", "Million", "Billion"};

std::size_t append_text(std::uint8_t* buffer, std::size_t position, const char* text) {
    while (*text != '\0') buffer[position++] = static_cast<std::uint8_t>(*text++);
    return position;
}

std::size_t append_word(std::uint8_t* buffer, std::size_t position, const char* text) {
    if (position != 0) buffer[position++] = static_cast<std::uint8_t>(' ');
    return append_text(buffer, position, text);
}

std::size_t append_group(std::uint8_t* buffer, std::size_t position, unsigned value) {
    if (value >= 100) {
        position = append_word(buffer, position, small[value / 100]);
        position = append_word(buffer, position, "Hundred");
        value %= 100;
    }
    if (value <= 20) {
        if (value != 0) position = append_word(buffer, position, small[value]);
    } else if (value % 10 == 0) {
        position = append_word(buffer, position, tens[value / 10]);
    } else {
        position = append_word(buffer, position, tens[value / 10]);
        position = append_word(buffer, position, small[value % 10]);
    }
    return position;
}
}

extern "C" std::int64_t integer_to_english(const std::int64_t* input, std::size_t length,
                                             std::uint8_t* output, std::size_t output_capacity) {
    if (input == nullptr || length != 1 || input[0] < INT32_MIN || input[0] > INT32_MAX) return -1;
    const std::int64_t value = input[0];
    std::uint8_t buffer[128];
    std::size_t position = 0;
    if (value == 0) {
        position = append_word(buffer, position, "Zero");
    } else if (value > 0) {
        unsigned groups[4];
        std::size_t count = 0;
        std::uint32_t remaining = static_cast<std::uint32_t>(value);
        while (remaining != 0) {
            groups[count++] = remaining % 1000;
            remaining /= 1000;
        }
        while (count > 0) {
            --count;
            if (groups[count] != 0) {
                position = append_group(buffer, position, groups[count]);
                if (count != 0) position = append_word(buffer, position, scales[count]);
            }
        }
    }
    if (position > output_capacity || (position != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < position; ++index) output[index] = buffer[index];
    return static_cast<std::int64_t>(position);
}

#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t MAX_INPUT_LENGTH = 512;
constexpr std::size_t MAX_OUTPUT_BYTES = 2560;
constexpr const char* MORSE[26] = {".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---", "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-", "..-", "...-", ".--", "-..-", "-.--", "--.."};
int letter_index(std::int64_t value) {
    if (value >= 'A' && value <= 'Z') return static_cast<int>(value - 'A');
    if (value >= 'a' && value <= 'z') return static_cast<int>(value - 'a');
    return -1;
}
void append_word(const std::int64_t* text, std::size_t start, std::size_t end,
                 std::uint8_t* scratch, std::size_t& written) {
    for (std::size_t pos = start; pos < end; ++pos) {
        const int index = letter_index(text[pos]);
        if (index >= 0) for (const char* code = MORSE[index]; *code != '\0'; ++code) scratch[written++] = static_cast<std::uint8_t>(*code);
        scratch[written++] = ' ';
    }
}
std::size_t encode(const std::int64_t* text, std::size_t length, std::uint8_t* scratch) {
    std::size_t end = length;
    while (end > 0 && text[end-1] == ' ') --end;
    if (end == 0) return 0;
    std::size_t written = 0, start = 0;
    for (std::size_t pos = 0; pos <= end; ++pos) {
        if (pos == end || text[pos] == ' ') {
            append_word(text, start, pos, scratch, written);
            if (pos < end) { scratch[written++] = '|'; scratch[written++] = ' '; }
            start = pos + 1;
        }
    }
    while (written > 0 && scratch[written-1] == ' ') --written;
    return written;
}
}

extern "C" std::int64_t morse_code_converter_encode(const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if ((input == nullptr && length != 0) || length > MAX_INPUT_LENGTH) return -1;
    for (std::size_t i = 0; i < length; ++i) if (input[i] < 0 || input[i] > 127) return -1;
    std::uint8_t scratch[MAX_OUTPUT_BYTES];
    const std::size_t written = encode(input, length, scratch);
    if (output == nullptr || capacity < written) return -2;
    if (written != 0) std::memcpy(output, scratch, written);
    return static_cast<std::int64_t>(written);
}

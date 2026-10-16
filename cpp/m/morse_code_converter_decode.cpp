#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t MAX_INPUT_LENGTH = 512;
constexpr std::size_t MAX_OUTPUT_BYTES = 512;
constexpr const char* MORSE[26] = {".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---", "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-", "..-", "...-", ".--", "-..-", "-.--", "--.."};
bool separator(const std::int64_t* text, std::size_t pos, std::size_t end) {
    return pos + 2 < end && text[pos] == 32 && text[pos+1] == 124 && text[pos+2] == 32;
}
std::uint8_t decode_token(const std::int64_t* text, std::size_t start, std::size_t end) {
    for (std::size_t letter = 0; letter < 26; ++letter) {
        const std::size_t n = std::strlen(MORSE[letter]);
        if (end-start != n) continue;
        std::size_t i = 0;
        while (i < n && text[start+i] == static_cast<std::uint8_t>(MORSE[letter][i])) ++i;
        if (i == n) return static_cast<std::uint8_t>('A' + letter);
    }
    return '?';
}
void append_word(const std::int64_t* text, std::size_t start, std::size_t end,
                 std::uint8_t* scratch, std::size_t& written) {
    if (start == end) { scratch[written++] = '?'; return; }
    while (end > start && text[end-1] == 32) --end;
    if (start == end) return;
    std::size_t token = start;
    for (std::size_t pos = start; pos <= end; ++pos) {
        if (pos == end || text[pos] == 32) { scratch[written++] = decode_token(text, token, pos); token = pos+1; }
    }
}
std::size_t decode(const std::int64_t* text, std::size_t length, std::uint8_t* scratch) {
    if (length == 0) { scratch[0] = '?'; return 1; }
    std::size_t end = length;
    while (end >= 3 && separator(text, end-3, end)) end -= 3;
    if (end == 0) return 0;
    std::size_t written=0, start=0, pos=0;
    while (pos+2 < end) {
        if (separator(text,pos,end)) { append_word(text,start,pos,scratch,written); scratch[written++]=' '; pos+=3; start=pos; }
        else ++pos;
    }
    append_word(text,start,end,scratch,written);
    return written;
}
}
extern "C" std::int64_t morse_code_converter_decode(const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if ((input == nullptr && length != 0) || length > MAX_INPUT_LENGTH) return -1;
    for (std::size_t i=0; i<length; ++i) if (input[i]<0 || input[i]>127) return -1;
    std::uint8_t scratch[MAX_OUTPUT_BYTES];
    const std::size_t written=decode(input,length,scratch);
    if (output==nullptr || capacity<written) return -2;
    if (written!=0) std::memcpy(output,scratch,written);
    return static_cast<std::int64_t>(written);
}

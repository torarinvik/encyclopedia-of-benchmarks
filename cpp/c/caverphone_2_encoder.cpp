#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 64, scratch = 128, code_bytes = 10;

void replace_all(char* text, std::size_t& length, const char* old, std::size_t old_len,
                 const char* replacement, std::size_t replacement_len) noexcept {
    char next[scratch];
    std::size_t out = 0;
    for (std::size_t i = 0; i < length;) {
        std::size_t j = 0;
        while (j < old_len && i + j < length && text[i + j] == old[j]) ++j;
        if (j == old_len) {
            for (j = 0; j < replacement_len; ++j) next[out++] = replacement[j];
            i += old_len;
        } else next[out++] = text[i++];
    }
    for (std::size_t i = 0; i < out; ++i) text[i] = next[i];
    length = out;
}

void replace_prefix(char* text, std::size_t& length, const char* old, std::size_t old_len,
                    const char* replacement, std::size_t replacement_len) noexcept {
    if (length < old_len) return;
    for (std::size_t i = 0; i < old_len; ++i) if (text[i] != old[i]) return;
    const std::size_t tail = length - old_len;
    for (std::size_t i = tail; i > 0; --i) text[replacement_len + i - 1] = text[old_len + i - 1];
    for (std::size_t i = 0; i < replacement_len; ++i) text[i] = replacement[i];
    length = replacement_len + tail;
}

void replace_suffix(char* text, std::size_t& length, const char* old, std::size_t old_len,
                    const char* replacement, std::size_t replacement_len) noexcept {
    if (length < old_len) return;
    const std::size_t start = length - old_len;
    for (std::size_t i = 0; i < old_len; ++i) if (text[start + i] != old[i]) return;
    for (std::size_t i = 0; i < replacement_len; ++i) text[start + i] = replacement[i];
    length = start + replacement_len;
}

void replace_char(char* text, std::size_t length, char old, char replacement) noexcept {
    for (std::size_t i = 0; i < length; ++i) if (text[i] == old) text[i] = replacement;
}

void squeeze(char* text, std::size_t& length, char letter, char marker) noexcept {
    std::size_t out = 0;
    for (std::size_t i = 0; i < length; ++i) {
        if (text[i] == letter && out > 0 && text[out - 1] == marker) continue;
        text[out++] = text[i] == letter ? marker : text[i];
    }
    length = out;
}

void encode(const std::int64_t* input, char result[code_bytes]) noexcept {
    char text[scratch];
    std::size_t n = static_cast<std::size_t>(input[0]);
    for (std::size_t i = 0; i < n; ++i) {
        const auto c = input[i + 1];
        text[i] = static_cast<char>(c >= 'A' && c <= 'Z' ? c + ('a' - 'A') : c);
    }
    if (n == 0) { for (std::size_t i = 0; i < code_bytes; ++i) result[i] = '1'; return; }
    if (text[n - 1] == 'e') --n;
    replace_prefix(text, n, "cough", 5, "cou2f", 5); replace_prefix(text, n, "rough", 5, "rou2f", 5);
    replace_prefix(text, n, "tough", 5, "tou2f", 5); replace_prefix(text, n, "enough", 6, "enou2f", 6);
    replace_prefix(text, n, "trough", 6, "trou2f", 6); replace_prefix(text, n, "gn", 2, "2n", 2);
    replace_suffix(text, n, "mb", 2, "m2", 2);
    replace_all(text, n, "cq", 2, "2q", 2); replace_all(text, n, "ci", 2, "si", 2);
    replace_all(text, n, "ce", 2, "se", 2); replace_all(text, n, "cy", 2, "sy", 2);
    replace_all(text, n, "tch", 3, "2ch", 3); replace_char(text, n, 'c', 'k');
    replace_char(text, n, 'q', 'k'); replace_char(text, n, 'x', 'k'); replace_char(text, n, 'v', 'f');
    replace_all(text, n, "dg", 2, "2g", 2); replace_all(text, n, "tio", 3, "sio", 3);
    replace_all(text, n, "tia", 3, "sia", 3); replace_char(text, n, 'd', 't');
    replace_all(text, n, "ph", 2, "fh", 2); replace_char(text, n, 'b', 'p');
    replace_all(text, n, "sh", 2, "s2", 2); replace_char(text, n, 'z', 's');
    if (n && (text[0]=='a'||text[0]=='e'||text[0]=='i'||text[0]=='o'||text[0]=='u')) text[0] = 'A';
    for (std::size_t i = 0; i < n; ++i) if (text[i]=='a'||text[i]=='e'||text[i]=='i'||text[i]=='o'||text[i]=='u') text[i]='3';
    replace_char(text, n, 'j', 'y'); replace_prefix(text, n, "y3", 2, "Y3", 2);
    replace_prefix(text, n, "y", 1, "A", 1); replace_char(text, n, 'y', '3');
    replace_all(text, n, "3gh3", 4, "3kh3", 4); replace_all(text, n, "gh", 2, "22", 2);
    replace_char(text, n, 'g', 'k');
    squeeze(text, n, 's', 'S'); squeeze(text, n, 't', 'T'); squeeze(text, n, 'p', 'P');
    squeeze(text, n, 'k', 'K'); squeeze(text, n, 'f', 'F'); squeeze(text, n, 'm', 'M'); squeeze(text, n, 'n', 'N');
    replace_all(text, n, "w3", 2, "W3", 2); replace_all(text, n, "wh3", 3, "Wh3", 3);
    replace_suffix(text, n, "w", 1, "3", 1); replace_char(text, n, 'w', '2');
    replace_prefix(text, n, "h", 1, "A", 1); replace_char(text, n, 'h', '2');
    replace_all(text, n, "r3", 2, "R3", 2); replace_suffix(text, n, "r", 1, "3", 1); replace_char(text, n, 'r', '2');
    replace_all(text, n, "l3", 2, "L3", 2); replace_suffix(text, n, "l", 1, "3", 1); replace_char(text, n, 'l', '2');
    std::size_t out = 0; for (std::size_t i = 0; i < n; ++i) if (text[i] != '2') text[out++] = text[i]; n = out;
    replace_suffix(text, n, "3", 1, "A", 1);
    out = 0; for (std::size_t i = 0; i < n; ++i) if (text[i] != '3') text[out++] = text[i]; n = out;
    for (std::size_t i = 0; i < code_bytes; ++i) result[i] = i < n ? text[i] : '1';
}
} // namespace

extern "C" std::int64_t caverphone_2_encoder(const std::int64_t* input, std::size_t length,
                                                std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_text + 1) return -1;
    const auto count = input[0];
    if (count < 0 || count > static_cast<std::int64_t>(max_text) || length != static_cast<std::size_t>(count) + 1) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) {
        const auto c = input[i + 1];
        if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'))) return -1;
    }
    if (output == nullptr || output_capacity < code_bytes) return -2;
    char result[code_bytes];
    encode(input, result);
    for (std::size_t i = 0; i < code_bytes; ++i) output[i] = static_cast<std::uint8_t>(result[i]);
    return static_cast<std::int64_t>(code_bytes);
}

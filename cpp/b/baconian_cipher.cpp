/* Baconian cipher with explicit Java, Python, and Rust source dialects. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxPayload = 1024;

int python_code_for_letter(int upper) noexcept {
    if (upper >= 'A' && upper <= 'I') return upper - 'A';
    if (upper == 'J') return 28;
    if (upper >= 'K' && upper <= 'U') return upper - 'A' - 1;
    if (upper == 'V') return 29;
    if (upper >= 'W' && upper <= 'Z') return upper - 'A' - 2;
    return -1;
}
int python_letter_for_code(int code) noexcept {
    if (code >= 0 && code <= 8) return 'a' + code;
    if (code == 28) return 'j';
    if (code == 29) return 'v';
    if (code >= 9 && code <= 19) return 'a' + code + 1;
    if (code >= 20 && code <= 23) return 'a' + code + 2;
    return -1;
}
int decode_code(const std::int64_t *payload, std::size_t start) noexcept {
    int code = 0;
    for (std::size_t bit = 0; bit < 5; ++bit) code = (code << 1) | (payload[start + bit] == 'B');
    return code;
}
void write_code(std::uint8_t *output, std::size_t &position, int code) noexcept {
    for (int bit = 4; bit >= 0; --bit)
        output[position++] = static_cast<std::uint8_t>(((code >> bit) & 1) ? 'B' : 'A');
}
bool python_decode_valid(const std::int64_t *payload, std::size_t length, std::size_t &output_length) noexcept {
    for (std::size_t i = 0; i < length; ++i)
        if (payload[i] != 'A' && payload[i] != 'B' && payload[i] != ' ') return false;
    std::size_t words = 0, letters = 0, i = 0;
    while (i < length) {
        while (i < length && payload[i] == ' ') ++i;
        if (i == length) break;
        const auto start = i;
        while (i < length && payload[i] != ' ') ++i;
        const auto word_length = i - start;
        if (word_length % 5 != 0) return false;
        for (std::size_t offset = 0; offset < word_length; offset += 5)
            if (python_letter_for_code(decode_code(payload, start + offset)) < 0) return false;
        letters += word_length / 5;
        ++words;
    }
    output_length = letters + (words == 0 ? 0 : words - 1);
    return true;
}
}

extern "C" std::int64_t baconian_cipher(const std::int64_t *values, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 2 || length > MaxPayload + 2) return -1;
    const auto mode = values[0], dialect = values[1];
    if ((mode != 0 && mode != 1) || dialect < 0 || dialect > 2) return -1;
    const auto n = length - 2;
    const auto *payload = values + 2;
    for (std::size_t i = 0; i < n; ++i) if (payload[i] < 0 || payload[i] > 127) return -1;

    std::size_t output_length = 0;
    if (mode == 0) {
        for (std::size_t i = 0; i < n; ++i) {
            const int upper = payload[i] >= 'a' && payload[i] <= 'z' ? static_cast<int>(payload[i]) - 32 : static_cast<int>(payload[i]);
            const bool is_letter = upper >= 'A' && upper <= 'Z';
            if (dialect == 0) { if (is_letter) output_length += 5; }
            else if (dialect == 1) {
                if (payload[i] == ' ') ++output_length;
                else if (is_letter) output_length += 5;
                else return -1;
            } else {
                if (is_letter) { if (upper > 'X') return -1; output_length += 5; }
                else ++output_length;
            }
        }
    } else if (dialect == 0) {
        if (n % 5 != 0) return -1;
        for (std::size_t i = 0; i < n; ++i) if (payload[i] != 'A' && payload[i] != 'B') return -1;
        for (std::size_t i = 0; i < n; i += 5) if (decode_code(payload, i) > 25) return -1;
        output_length = n / 5;
    } else if (dialect == 1) {
        if (!python_decode_valid(payload, n, output_length)) return -1;
    } else output_length = (n + 4) / 5;
    if (output_capacity < output_length || (output_length > 0 && output == nullptr)) return -2;

    std::size_t write = 0;
    if (mode == 0) {
        for (std::size_t i = 0; i < n; ++i) {
            const int upper = payload[i] >= 'a' && payload[i] <= 'z' ? static_cast<int>(payload[i]) - 32 : static_cast<int>(payload[i]);
            if (dialect == 0) { if (upper >= 'A' && upper <= 'Z') write_code(output, write, upper == 'I' ? 9 : upper - 'A'); }
            else if (dialect == 1) {
                if (payload[i] == ' ') output[write++] = ' ';
                else write_code(output, write, python_code_for_letter(upper));
            } else {
                if (upper >= 'A' && upper <= 'Z') write_code(output, write, upper - 'A');
                else output[write++] = static_cast<std::uint8_t>(payload[i]);
            }
        }
    } else if (dialect == 0) {
        for (std::size_t i = 0; i < n; i += 5) {
            const int code = decode_code(payload, i);
            output[write++] = static_cast<std::uint8_t>(code == 8 || code == 9 ? 'I' : 'A' + code);
        }
    } else if (dialect == 1) {
        std::size_t i = 0; bool first_word = true;
        while (i < n) {
            while (i < n && payload[i] == ' ') ++i;
            if (i == n) break;
            if (!first_word) output[write++] = ' ';
            first_word = false;
            while (i < n && payload[i] != ' ') { output[write++] = static_cast<std::uint8_t>(python_letter_for_code(decode_code(payload, i))); i += 5; }
        }
    } else {
        for (std::size_t i = 0; i < n; i += 5) {
            if (n - i < 5) { output[write++] = ' '; continue; }
            int code = 0; bool valid = true;
            for (std::size_t bit = 0; bit < 5; ++bit) { const auto value = payload[i + bit]; if (value != 'A' && value != 'B') valid = false; code = (code << 1) | (value == 'B'); }
            output[write++] = static_cast<std::uint8_t>(valid && code < 24 ? 'A' + code : ' ');
        }
    }
    return static_cast<std::int64_t>(output_length);
}

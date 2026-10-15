/* Baconian cipher with explicit Java, Python, and Rust source dialects. */
#include <stddef.h>
#include <stdint.h>

#define MAX_PAYLOAD 1024

static int python_code_for_letter(int upper)
{
    if (upper >= 'A' && upper <= 'I') return upper - 'A';
    if (upper == 'J') return 28;
    if (upper >= 'K' && upper <= 'U') return upper - 'A' - 1;
    if (upper == 'V') return 29;
    if (upper >= 'W' && upper <= 'Z') return upper - 'A' - 2;
    return -1;
}

static int python_letter_for_code(int code)
{
    if (code >= 0 && code <= 8) return 'a' + code;
    if (code == 28) return 'j';
    if (code == 29) return 'v';
    if (code >= 9 && code <= 19) return 'a' + code + 1;
    if (code >= 20 && code <= 23) return 'a' + code + 2;
    return -1;
}

static int decode_code(const int64_t *payload, size_t start)
{
    int code = 0;
    for (size_t bit = 0; bit < 5; ++bit)
        code = (code << 1) | (payload[start + bit] == 'B');
    return code;
}

static void write_code(uint8_t *output, size_t *position, int code)
{
    for (int bit = 4; bit >= 0; --bit)
        output[(*position)++] = (uint8_t)(((code >> bit) & 1) ? 'B' : 'A');
}

static int python_decode_valid(const int64_t *payload, size_t length, size_t *output_length)
{
    for (size_t i = 0; i < length; ++i)
        if (payload[i] != 'A' && payload[i] != 'B' && payload[i] != ' ') return 0;
    size_t words = 0, letters = 0, i = 0;
    while (i < length) {
        while (i < length && payload[i] == ' ') ++i;
        if (i == length) break;
        const size_t start = i;
        while (i < length && payload[i] != ' ') ++i;
        const size_t word_length = i - start;
        if (word_length % 5 != 0) return 0;
        for (size_t offset = 0; offset < word_length; offset += 5)
            if (python_letter_for_code(decode_code(payload, start + offset)) < 0) return 0;
        letters += word_length / 5;
        ++words;
    }
    *output_length = letters + (words == 0 ? 0 : words - 1);
    return 1;
}

int64_t baconian_cipher(const int64_t *values, size_t length,
                        uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > MAX_PAYLOAD + 2) return -1;
    const int64_t mode = values[0], dialect = values[1];
    if ((mode != 0 && mode != 1) || dialect < 0 || dialect > 2) return -1;
    const size_t n = length - 2;
    const int64_t *payload = values + 2;
    for (size_t i = 0; i < n; ++i) if (payload[i] < 0 || payload[i] > 127) return -1;

    size_t output_length = 0;
    if (mode == 0) {
        for (size_t i = 0; i < n; ++i) {
            int upper = (payload[i] >= 'a' && payload[i] <= 'z') ? (int)payload[i] - 32 : (int)payload[i];
            const int is_letter = upper >= 'A' && upper <= 'Z';
            if (dialect == 0) {
                if (is_letter) output_length += 5;
            } else if (dialect == 1) {
                if (payload[i] == ' ') ++output_length;
                else if (is_letter) output_length += 5;
                else return -1;
            } else {
                if (is_letter) {
                    if (upper > 'X') return -1;
                    output_length += 5;
                } else ++output_length;
            }
        }
    } else if (dialect == 0) {
        if (n % 5 != 0) return -1;
        for (size_t i = 0; i < n; ++i) if (payload[i] != 'A' && payload[i] != 'B') return -1;
        for (size_t i = 0; i < n; i += 5) if (decode_code(payload, i) > 25) return -1;
        output_length = n / 5;
    } else if (dialect == 1) {
        if (!python_decode_valid(payload, n, &output_length)) return -1;
    } else {
        output_length = (n + 4) / 5;
    }
    if (output_capacity < output_length || (output_length > 0 && output == NULL)) return -2;

    size_t write = 0;
    if (mode == 0) {
        for (size_t i = 0; i < n; ++i) {
            int upper = (payload[i] >= 'a' && payload[i] <= 'z') ? (int)payload[i] - 32 : (int)payload[i];
            if (dialect == 0) {
                if (upper >= 'A' && upper <= 'Z') write_code(output, &write, upper == 'I' ? 9 : upper - 'A');
            } else if (dialect == 1) {
                if (payload[i] == ' ') output[write++] = ' ';
                else write_code(output, &write, python_code_for_letter(upper));
            } else {
                if (upper >= 'A' && upper <= 'Z') write_code(output, &write, upper - 'A');
                else output[write++] = (uint8_t)payload[i];
            }
        }
    } else if (dialect == 0) {
        for (size_t i = 0; i < n; i += 5) {
            const int code = decode_code(payload, i);
            output[write++] = (uint8_t)(code == 8 || code == 9 ? 'I' : 'A' + code);
        }
    } else if (dialect == 1) {
        size_t i = 0;
        int first_word = 1;
        while (i < n) {
            while (i < n && payload[i] == ' ') ++i;
            if (i == n) break;
            if (!first_word) output[write++] = ' ';
            first_word = 0;
            while (i < n && payload[i] != ' ') {
                output[write++] = (uint8_t)python_letter_for_code(decode_code(payload, i));
                i += 5;
            }
        }
    } else {
        for (size_t i = 0; i < n; i += 5) {
            if (n - i < 5) { output[write++] = ' '; continue; }
            int code = 0, valid = 1;
            for (size_t bit = 0; bit < 5; ++bit) {
                const int64_t value = payload[i + bit];
                if (value != 'A' && value != 'B') valid = 0;
                code = (code << 1) | (value == 'B');
            }
            output[write++] = (uint8_t)(valid && code < 24 ? 'A' + code : ' ');
        }
    }
    return (int64_t)output_length;
}

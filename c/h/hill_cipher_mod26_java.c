#include <stddef.h>
#include <stdint.h>

int64_t hill_cipher_mod26_java(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 1 || length > 257 || (input[0] != 0 && input[0] != 1)) return -1;
    const int64_t *key = input[0] == 0 ? (const int64_t[]){3,3,2,5} : (const int64_t[]){15,17,20,9};
    uint8_t text[256]; size_t text_length = 0;
    for (size_t i = 1; i < length; ++i) {
        if (input[i] < 0 || input[i] > 127) return -1;
        int64_t c = input[i];
        if (c >= 'a' && c <= 'z') c -= 'a' - 'A';
        if (c >= 'A' && c <= 'Z') text[text_length++] = (uint8_t)c;
    }
    if (text_length & 1) text[text_length++] = 'X';
    if (text_length > capacity || (text_length > 0 && !output)) return -2;
    for (size_t i = 0; i < text_length; i += 2) {
        const int a = text[i] - 'A', b = text[i + 1] - 'A';
        output[i] = (uint8_t)('A' + (key[0] * a + key[1] * b) % 26);
        output[i + 1] = (uint8_t)('A' + (key[2] * a + key[3] * b) % 26);
    }
    return (int64_t)text_length;
}

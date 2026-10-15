#include <stddef.h>
#include <stdint.h>

static int symbol_value(int64_t value) {
    if (value >= 'a' && value <= 'z') value -= 'a' - 'A';
    if (value >= 'A' && value <= 'Z') return (int)(value - 'A');
    if (value >= '0' && value <= '9') return (int)(value - '0') + 26;
    return -1;
}

int64_t hill_cipher_mod36(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || input[0] < 0 || input[0] > 1) return -1;
    const int64_t raw_length = input[1];
    if (raw_length < 1 || raw_length > 256 || length != (size_t)raw_length + 2) return -1;
    int values[256]; size_t count = 0;
    for (size_t i = 0; i < (size_t)raw_length; ++i) {
        const int64_t byte = input[2 + i];
        if (byte < 0 || byte > 127) return -1;
        const int value = symbol_value(byte);
        if (value >= 0) values[count++] = value;
    }
    if (count == 0) return -1;
    if ((count & 1u) != 0) { values[count] = values[count - 1]; ++count; }
    if (output == NULL || capacity < count) return -2;
    const int decrypt = (int)input[0];
    for (size_t i = 0; i < count; i += 2) {
        const int a = values[i], b = values[i + 1];
        const int first = decrypt ? (6 * a + 25 * b) % 36 : (2 * a + 5 * b) % 36;
        const int second = decrypt ? (5 * a + 26 * b) % 36 : (a + 6 * b) % 36;
        output[i] = (uint8_t)(first < 26 ? 'A' + first : '0' + first - 26);
        output[i + 1] = (uint8_t)(second < 26 ? 'A' + second : '0' + second - 26);
    }
    return (int64_t)count;
}

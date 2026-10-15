#include <stddef.h>
#include <stdint.h>

static const uint8_t alphabet[97] = {65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 126, 33, 64, 35, 36, 37, 94, 38, 42, 40, 41, 95, 43, 96, 45, 61, 91, 93, 123, 125, 124, 59, 39, 34, 58, 44, 46, 47, 60, 62, 63, 92, 13, 10, 32};
static const int64_t encrypt_key[4] = {2, 5, 1, 6};
static const int64_t decrypt_key[4] = {84, 27, 83, 28};

static int alphabet_index(int64_t value) {
    for (int index = 0; index < 97; ++index) if (alphabet[index] == value) return index;
    return -1;
}

int64_t hill_cipher_mod97_cpp(const int64_t *values, size_t length, uint8_t *output, size_t capacity) {
    if (values == NULL || length < 3 || length > 258) return -1;
    int64_t operation = values[0], raw_length = values[1];
    if ((operation != 0 && operation != 1) || raw_length < 1 || raw_length > 256 || length != (size_t)raw_length + 2) return -1;
    size_t text_length = (size_t)raw_length;
    uint8_t indices[256];
    for (size_t index = 0; index < text_length; ++index) {
        int mapped = alphabet_index(values[index + 2]);
        if (mapped < 0) return -1;
        indices[index] = (uint8_t)mapped;
    }
    size_t output_length = text_length + (text_length % 2);
    if (output == NULL || capacity < output_length) return -2;
    const int64_t *key = operation == 0 ? encrypt_key : decrypt_key;
    for (size_t offset = 0; offset < output_length; offset += 2) {
        int64_t first = indices[offset];
        int64_t second = offset + 1 < text_length ? indices[offset + 1] : 0;
        size_t row0 = (size_t)((key[0] * first + key[1] * second) % 97);
        size_t row1 = (size_t)((key[2] * first + key[3] * second) % 97);
        output[offset] = alphabet[row0];
        output[offset + 1] = alphabet[row1];
    }
    return (int64_t)output_length;
}

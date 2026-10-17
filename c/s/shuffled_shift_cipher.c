#include <stddef.h>
#include <stdint.h>

#define PASSCODE_MAX 20
#define PLAINTEXT_MAX 256
#define INPUT_MAX_PARSEABLE 279
#define ALPHABET_LENGTH 97

static const char alphabet[] =
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~ \t\n";

int64_t shuffled_shift_cipher(const int64_t *input, size_t input_length,
                              char *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2 || input_length > INPUT_MAX_PARSEABLE) return -1;

    const int64_t passcode_length_value = input[0];
    const int64_t plaintext_length_value = input[1];
    if (passcode_length_value < 1 || passcode_length_value > PASSCODE_MAX ||
        plaintext_length_value < 0 || plaintext_length_value > PLAINTEXT_MAX) return -1;

    const size_t passcode_length = (size_t)passcode_length_value;
    const size_t plaintext_length = (size_t)plaintext_length_value;
    if (input_length != 2 + passcode_length + plaintext_length) return -1;

    int breakpoint[128] = {0};
    for (size_t i = 0; i < passcode_length; ++i) {
        const int64_t value = input[2 + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') ||
              (value >= '0' && value <= '9'))) return -1;
        breakpoint[(int)value] = 1;
    }
    for (size_t i = 0; i < plaintext_length; ++i) {
        const int64_t value = input[2 + passcode_length + i];
        if (value < 0 || value >= 128) return -1;
        int found = 0;
        for (size_t j = 0; j < ALPHABET_LENGTH; ++j) {
            if ((unsigned char)alphabet[j] == (unsigned char)value) {
                found = 1;
                break;
            }
        }
        if (!found) return -1;
    }

    int key[ALPHABET_LENGTH];
    int key_index[128];
    int segment[ALPHABET_LENGTH];
    for (int i = 0; i < 128; ++i) key_index[i] = -1;
    size_t key_length = 0;
    size_t segment_length = 0;
    for (size_t i = 0; i < ALPHABET_LENGTH; ++i) {
        const int value = (unsigned char)alphabet[i];
        segment[segment_length++] = value;
        if (breakpoint[value] || i + 1 == ALPHABET_LENGTH) {
            while (segment_length > 0) key[key_length++] = segment[--segment_length];
        }
    }
    for (size_t i = 0; i < ALPHABET_LENGTH; ++i) key_index[key[i]] = (int)i;

    int shift = 0;
    for (size_t i = 0; i < passcode_length; ++i) {
        const int value = (int)input[2 + i];
        shift += (i % 2 == 0) ? value : -value;
    }
    if (shift <= 0) shift = (int)passcode_length;
    shift %= ALPHABET_LENGTH;

    if (output == NULL || output_capacity < plaintext_length) return -2;
    for (size_t i = 0; i < plaintext_length; ++i) {
        const int value = (int)input[2 + passcode_length + i];
        const int index = key_index[value];
        output[i] = (char)key[(index + shift) % ALPHABET_LENGTH];
    }
    return (int64_t)plaintext_length;
}

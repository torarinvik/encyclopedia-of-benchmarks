#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define MAX_KEYWORD_LENGTH 26
#define MAX_MESSAGE_LENGTH 512
#define MAX_INPUT_LENGTH (3 + MAX_KEYWORD_LENGTH + MAX_MESSAGE_LENGTH + 1)

int64_t keyword_shifted_alphabet(const int64_t *input, size_t length,
                                 uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t operation = input[0];
    const int64_t keyword_length_value = input[1];
    const int64_t message_length_value = input[2];
    if ((operation != 0 && operation != 1) || keyword_length_value < 1 ||
        keyword_length_value > MAX_KEYWORD_LENGTH || message_length_value < 1 ||
        message_length_value > MAX_MESSAGE_LENGTH) return -1;
    const size_t keyword_length = (size_t)keyword_length_value;
    const size_t message_length = (size_t)message_length_value;
    if (length != 3 + keyword_length + message_length) return -1;

    uint8_t keyword[MAX_KEYWORD_LENGTH];
    bool seen[26] = {0};
    for (size_t i = 0; i < keyword_length; ++i) {
        const int64_t value = input[3 + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
        const uint8_t lower = (uint8_t)(value >= 'A' && value <= 'Z' ? value + 32 : value);
        const size_t index = (size_t)(lower - 'a');
        if (seen[index]) return -1;
        seen[index] = true;
        keyword[i] = lower;
    }
    uint8_t message[MAX_MESSAGE_LENGTH];
    for (size_t i = 0; i < message_length; ++i) {
        const int64_t value = input[3 + keyword_length + i];
        if (value < 0 || value > 127) return -1;
        message[i] = (uint8_t)value;
    }

    uint8_t cipher_alphabet[26], encode[26], decode[26];
    size_t cipher_length = 0;
    for (size_t i = 0; i < keyword_length; ++i) cipher_alphabet[cipher_length++] = keyword[i];
    for (uint8_t letter = 'a'; letter <= 'z'; ++letter) {
        const size_t index = (size_t)(letter - 'a');
        if (!seen[index]) cipher_alphabet[cipher_length++] = letter;
    }
    for (size_t i = 0; i < 26; ++i) {
        encode[i] = cipher_alphabet[i];
        decode[(size_t)(cipher_alphabet[i] - 'a')] = (uint8_t)('a' + i);
    }

    if (output_capacity < message_length || output == NULL) return -2;
    for (size_t i = 0; i < message_length; ++i) {
        const uint8_t value = message[i];
        const int uppercase = value >= 'A' && value <= 'Z';
        size_t index;
        if (uppercase) index = (size_t)(value - 'A');
        else if (value >= 'a' && value <= 'z') index = (size_t)(value - 'a');
        else { output[i] = value; continue; }
        uint8_t translated = operation == 0 ? encode[index] : decode[index];
        output[i] = uppercase ? (uint8_t)(translated - ('a' - 'A')) : translated;
    }
    return (int64_t)message_length;
}

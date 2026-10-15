/* Keyed Morse trigraph fractionation. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 256
#define MAX_KEY 64
#define MAX_MORSE 1300
#define MAX_RESULT 800

static const uint8_t morse_code[26] = {1,8,10,4,0,2,6,0,0,7,5,4,3,2,7,6,13,2,0,1,1,1,3,9,11,12};
static const uint8_t morse_length[26] = {2,4,4,3,1,4,3,4,2,4,3,4,2,2,3,4,4,3,3,1,3,4,3,4,4,4};

static void make_keyed_alphabet(const int64_t *input, size_t start, size_t length, uint8_t keyed[26])
{
    uint8_t seen[26] = {0};
    size_t count = 0;
    for (size_t i = 0; i < length; ++i) {
        int64_t value = input[start + i];
        if (value >= 'a' && value <= 'z') value -= 32;
        const size_t letter = (size_t)(value - 'A');
        if (!seen[letter]) { seen[letter] = 1; keyed[count++] = (uint8_t)value; }
    }
    for (size_t i = 0; i < 26; ++i) if (!seen[i]) keyed[count++] = (uint8_t)('A' + i);
}

static int morse_letter(const uint8_t *morse, size_t length)
{
    uint8_t code = 0;
    for (size_t i = 0; i < length; ++i) code = (uint8_t)(code * 2 + (morse[i] == '-'));
    for (size_t letter = 0; letter < 26; ++letter)
        if (morse_length[letter] == length && morse_code[letter] == code) return (int)letter;
    return -1;
}

int64_t fractionated_morse_cipher(const int64_t *input, size_t length,
                                  uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 3 || length > 3 + MAX_TEXT + MAX_KEY) return -1;
    const int64_t mode = input[0], text_value = input[1], key_value = input[2];
    if ((mode != 0 && mode != 1) || text_value < 0 || text_value > MAX_TEXT || key_value < 0 || key_value > MAX_KEY) return -1;
    const size_t text_length = (size_t)text_value, key_length = (size_t)key_value;
    if (length != 3 + text_length + key_length) return -1;
    const size_t key_start = 3 + text_length;
    for (size_t i = 0; i < key_length; ++i) {
        const int64_t value = input[key_start + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
    }
    for (size_t i = 0; i < text_length; ++i) {
        const int64_t value = input[3 + i];
        if (mode == 0) {
            if (value != ' ' && !((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
        } else if (value < 'A' || value > 'Z') return -1;
    }
    uint8_t keyed[26];
    make_keyed_alphabet(input, key_start, key_length, keyed);
    uint8_t result[MAX_RESULT];
    size_t result_length = 0;
    if (mode == 0) {
        uint8_t morse[MAX_MORSE];
        size_t morse_length_value = 0;
        for (size_t i = 0; i < text_length; ++i) {
            if (i != 0) morse[morse_length_value++] = 'x';
            int64_t value = input[3 + i];
            if (value == ' ') continue;
            if (value >= 'a' && value <= 'z') value -= 32;
            const size_t letter = (size_t)(value - 'A');
            for (size_t bit = 0; bit < morse_length[letter]; ++bit) {
                const uint8_t mask = (uint8_t)(1u << (morse_length[letter] - bit - 1));
                morse[morse_length_value++] = (morse_code[letter] & mask) ? '-' : '.';
            }
        }
        const size_t padding = 3 - morse_length_value % 3;
        for (size_t i = 0; i < padding; ++i) morse[morse_length_value++] = 'x';
        for (size_t i = 0; i < morse_length_value; i += 3) {
            const uint8_t symbols[3] = {morse[i], morse[i + 1], morse[i + 2]};
            size_t trigram = 0;
            for (size_t j = 0; j < 3; ++j) trigram = trigram * 3 + (symbols[j] == '.' ? 0 : symbols[j] == '-' ? 1 : 2);
            if (trigram < 26) result[result_length++] = keyed[trigram];
        }
    } else {
        uint8_t morse[MAX_MORSE];
        size_t morse_length_value = 0;
        for (size_t i = 0; i < text_length; ++i) {
            size_t trigram = 0;
            while (trigram < 26 && keyed[trigram] != input[3 + i]) ++trigram;
            if (trigram == 26) return -1;
            const uint8_t symbols[3] = {(uint8_t)(trigram / 9), (uint8_t)((trigram / 3) % 3), (uint8_t)(trigram % 3)};
            const uint8_t alphabet[3] = {'.', '-', 'x'};
            for (size_t j = 0; j < 3; ++j) morse[morse_length_value++] = alphabet[symbols[j]];
        }
        size_t segment_start = 0;
        for (size_t i = 0; i <= morse_length_value; ++i) {
            if (i != morse_length_value && morse[i] != 'x') continue;
            const size_t segment_length = i - segment_start;
            if (segment_length == 0) result[result_length++] = ' ';
            else {
                const int letter = morse_letter(morse + segment_start, segment_length);
                if (letter < 0) return -1;
                result[result_length++] = (uint8_t)('A' + letter);
            }
            segment_start = i + 1;
        }
        size_t first = 0;
        while (first < result_length && result[first] == ' ') ++first;
        while (result_length > first && result[result_length - 1] == ' ') --result_length;
        if (first != 0) {
            for (size_t i = first; i < result_length; ++i) result[i - first] = result[i];
            result_length -= first;
        }
    }
    if (output_capacity < result_length || (result_length != 0 && output == NULL)) return -2;
    for (size_t i = 0; i < result_length; ++i) output[i] = result[i];
    return (int64_t)result_length;
}

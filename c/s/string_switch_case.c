#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 1024
#define MAX_INPUT_LENGTH (MAX_TEXT_LENGTH + 3)

static int is_space(int64_t value) {
    return value == 32 || (value >= 9 && value <= 13) || (value >= 28 && value <= 31);
}

static int is_word(int64_t value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') ||
           (value >= '0' && value <= '9');
}

int64_t string_switch_case(const int64_t *input, size_t length,
                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    int64_t mode = input[0], separator = input[1], text_length = input[2];
    if (mode < 0 || mode > 8 || separator < 0 || separator > 127 ||
        text_length < 0 || text_length > MAX_TEXT_LENGTH ||
        length != (size_t)text_length + 3 ||
        ((mode != 3 && mode != 4) && separator != 0)) return -1;
    for (size_t i = 0; i < (size_t)text_length; ++i)
        if (input[i + 3] < 0 || input[i + 3] > 127) return -1;

    uint8_t result[MAX_TEXT_LENGTH];
    size_t used = 0;
    if (mode <= 2) {
        int at_word_start = 1;
        for (size_t i = 0; i < (size_t)text_length; ++i) {
            int64_t value = input[i + 3];
            if (!is_word(value)) { at_word_start = 1; continue; }
            if (at_word_start) {
                if (value >= 'a' && value <= 'z') value -= 32;
                at_word_start = 0;
            } else if (value >= 'A' && value <= 'Z') value += 32;
            result[used++] = (uint8_t)value;
        }
        if (mode == 2) {
            if (used == 0) {
                static const uint8_t empty_message[] = "not valid string";
                for (size_t i = 0; i < sizeof(empty_message) - 1; ++i) result[used++] = empty_message[i];
            } else if (result[0] >= 'A' && result[0] <= 'Z') result[0] += 32;
        }
    } else {
        int upper = mode == 4 || mode == 6 || mode == 8;
        uint8_t delimiter = mode <= 4 ? (uint8_t)separator :
                            mode <= 6 ? (uint8_t)'_' : (uint8_t)'-';
        int group_has_word = 0, pending_space = 0;
        for (size_t i = 0; i < (size_t)text_length; ++i) {
            int64_t value = input[i + 3];
            if (is_space(value)) { if (group_has_word) pending_space = 1; continue; }
            if (!is_word(value)) { group_has_word = 0; pending_space = 0; continue; }
            if (pending_space && group_has_word) result[used++] = delimiter;
            pending_space = 0;
            if (upper && value >= 'a' && value <= 'z') value -= 32;
            else if (!upper && value >= 'A' && value <= 'Z') value += 32;
            result[used++] = (uint8_t)value;
            group_has_word = 1;
        }
    }
    if (used > capacity || (used != 0 && output == NULL)) return -2;
    for (size_t i = 0; i < used; ++i) output[i] = result[i];
    return (int64_t)used;
}

/* Apply the pinned JavaScript title-case behavior to bounded ASCII words. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256

int64_t title_case_conversion(const int64_t *input, size_t length,
                              uint8_t *output, size_t output_capacity)
{
    if (length == 0 || length > MAX_LENGTH + 1 || input == NULL) return -1;
    int64_t declared = input[0];
    if (declared < 0 || declared > MAX_LENGTH || length != (size_t)declared + 1)
        return -1;

    for (size_t index = 0; index < (size_t)declared; ++index) {
        int64_t value = input[index + 1];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') || value == ' '))
            return -1;
        if (value == ' ' && (index == 0 || index + 1 == (size_t)declared || input[index] == ' '))
            return -1;
    }
    if (output_capacity < (size_t)declared + 1) return -2;

    int at_word_start = 1;
    for (size_t index = 0; index < (size_t)declared; ++index) {
        int64_t value = input[index + 1];
        if (value == ' ') {
            at_word_start = 1;
        } else if (at_word_start) {
            if (value >= 'a' && value <= 'z') value -= 'a' - 'A';
            at_word_start = 0;
        } else if (value >= 'A' && value <= 'Z') {
            value += 'a' - 'A';
        }
        output[index] = (uint8_t)value;
    }
    output[declared] = 0;
    return declared;
}

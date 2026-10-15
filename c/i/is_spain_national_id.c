#include <stddef.h>
#include <stdint.h>

static const char CHECK_LETTERS[] = "TRWAGMYFPDXBNJZSQVHLCKE";

int64_t is_spain_national_id(const int64_t *input, size_t length) {
    if (input == NULL || (length != 9 && length != 10)) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (input[index] < 0 || input[index] > 127) return -1;
    }
    if (length == 10 && input[8] != '-') return -1;
    int64_t number = 0;
    for (size_t index = 0; index < 8; ++index) {
        if (input[index] < '0' || input[index] > '9') return -1;
        number = number * 10 + input[index] - '0';
    }
    int64_t letter = input[length - 1];
    if (letter >= 'a' && letter <= 'z') letter -= 'a' - 'A';
    if (letter < 'A' || letter > 'Z') return -1;
    return letter == CHECK_LETTERS[number % 23] ? 1 : 0;
}

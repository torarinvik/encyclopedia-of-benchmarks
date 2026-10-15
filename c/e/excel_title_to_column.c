#include <stddef.h>
#include <stdint.h>

int64_t excel_title_to_column(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > 13) return -1;
    const int64_t count = values[0];
    if (count < 1 || count > 12 || length != (size_t)(1 + count)) return -1;

    int64_t column = 0;
    for (int64_t index = 0; index < count; ++index) {
        int64_t letter = values[1 + index];
        if (letter >= 97 && letter <= 122) letter -= 32;
        if (letter < 65 || letter > 90) return -1;
        column = column * 26 + (letter - 65 + 1);
    }
    return column;
}

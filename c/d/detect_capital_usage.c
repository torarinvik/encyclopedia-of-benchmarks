#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024

static int is_upper(int64_t value) { return value >= 65 && value <= 90; }
static int is_lower(int64_t value) { return value >= 97 && value <= 122; }
static int valid_input(const int64_t *input, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && input == NULL)) return 0;
    for (size_t index = 0; index < length; ++index)
        if (!is_upper(input[index]) && !is_lower(input[index])) return 0;
    return 1;
}

/* Classify by counting uppercase letters. */
int64_t detect_capital_usage(const int64_t *input, size_t length)
{
    if (!valid_input(input, length)) return -1;
    size_t uppercase_count = 0;
    for (size_t index = 0; index < length; ++index)
        if (is_upper(input[index])) ++uppercase_count;
    return uppercase_count == 0 || uppercase_count == length ||
           (uppercase_count == 1 && length != 0 && is_upper(input[0]));
}

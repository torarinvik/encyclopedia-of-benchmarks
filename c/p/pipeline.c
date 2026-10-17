#include <stddef.h>
#include <stdint.h>

#define MAX_STAGE_COUNT 32
#define MAX_INPUT_LENGTH (2 + 2 * MAX_STAGE_COUNT)

int64_t pipeline(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;

    const int64_t initial = values[0];
    const int64_t stage_count = values[1];
    if (initial < 0 || initial > 2 || stage_count < 1 || stage_count > MAX_STAGE_COUNT) return -1;
    if (length != (size_t)(2 + 2 * stage_count)) return -1;

    int64_t result = initial;
    for (int64_t index = 0; index < stage_count; ++index) {
        const int64_t operation = values[2 + 2 * index];
        const int64_t argument = values[3 + 2 * index];
        if (argument < 0 || argument > 2) return -1;
        if (operation == 0) result += argument;
        else if (operation == 1) result *= argument;
        else return -1;
    }
    return result;
}

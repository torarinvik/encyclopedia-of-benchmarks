/* Return the absent value from the inclusive range 0 through array length. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 1024

int64_t missing_number(const int64_t *values, size_t length)
{
    if (length > MAX_VALUES || (length != 0 && values == NULL)) return -1;
    bool seen[MAX_VALUES + 1] = {false};
    int64_t actual_sum = 0;
    for (size_t i = 0; i < length; ++i) {
        int64_t value = values[i];
        if (value < 0 || value > (int64_t)length || seen[value]) return -1;
        seen[value] = true;
        actual_sum += value;
    }
    int64_t n = (int64_t)length;
    return n * (n + 1) / 2 - actual_sum;
}

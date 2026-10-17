#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 9

int64_t mul_array(const int64_t *values, size_t length)
{
    if (length > MAX_INPUT_LENGTH) return -1;
    if (length == 0) return 1;
    if (values == NULL) return -1;

    int64_t product = 1;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = values[index];
        if (value < 0 || value > 99) return -1;
        product *= value;
    }
    return product;
}

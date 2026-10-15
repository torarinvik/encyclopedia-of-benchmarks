/* Check the strict polygon inequality for a set of positive side lengths. */
#include <stddef.h>
#include <stdint.h>

#define MAX_SIDES 256
#define MAX_SIDE_LENGTH INT64_C(1000000000)

int64_t check_polygon(const int64_t *values, size_t length,
                     uint8_t *output, size_t output_capacity)
{
    (void)output;
    (void)output_capacity;
    if (values == NULL || length < 3 || length > MAX_SIDES) return -1;

    int64_t total = 0;
    int64_t largest = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t side = values[index];
        if (side <= 0 || side > MAX_SIDE_LENGTH) return -1;
        total += side;
        if (side > largest) largest = side;
    }
    return largest < total - largest ? 1 : 0;
}

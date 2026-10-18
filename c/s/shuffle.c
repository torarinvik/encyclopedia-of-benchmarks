/* Replay a bounded forward Fisher–Yates shuffle using explicit draw offsets. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256
#define MAX_PARSEABLE_INPUT_LENGTH 513

static int exact_integer_in_range(double value, int64_t minimum, int64_t maximum,
                                  int64_t *integer)
{
    if (!isfinite(value) || value < (double)minimum || value > (double)maximum) return 0;
    const int64_t converted = (int64_t)value;
    if ((double)converted != value) return 0;
    *integer = converted;
    return 1;
}

int64_t shuffle(const double *input, size_t input_length,
                double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;

    int64_t count_value;
    if (!exact_integer_in_range(input[0], 0, MAX_LENGTH, &count_value)) return -1;
    const size_t count = (size_t)count_value;
    const size_t offset_count = count > 0 ? count - 1 : 0;
    const size_t expected_length = 1 + count + offset_count;
    if (input_length != expected_length) return -1;

    int64_t values[MAX_LENGTH] = {0};
    size_t offsets[MAX_LENGTH] = {0};
    for (size_t index = 0; index < count; ++index) {
        int64_t value;
        if (!exact_integer_in_range(input[1 + index], INT32_MIN, INT32_MAX, &value)) return -1;
        values[index] = value;
    }
    for (size_t index = 0; index < offset_count; ++index) {
        int64_t offset;
        const int64_t maximum_offset = (int64_t)(count - 1 - index);
        if (!exact_integer_in_range(input[1 + count + index], 0, maximum_offset, &offset)) return -1;
        offsets[index] = (size_t)offset;
    }

    if (output == NULL || output_capacity < count) return -2;
    for (size_t index = 0; index < offset_count; ++index) {
        const size_t other = index + offsets[index];
        const int64_t temporary = values[index];
        values[index] = values[other];
        values[other] = temporary;
    }
    for (size_t index = 0; index < count; ++index) output[index] = (double)values[index];
    return (int64_t)count;
}

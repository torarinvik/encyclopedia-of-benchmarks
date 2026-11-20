#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_VALUES = 64, MAX_INPUT_LENGTH = 67, SAMPLE_THRESHOLD = 24 };

static int64_t select_kth(int64_t *values, size_t left, size_t right, size_t target)
{
    while (1) {
        if (right - left > SAMPLE_THRESHOLD) {
            const size_t size = right - left + 1;
            const size_t relative_rank = target - left + 1;
            const double z = sqrt(log((double)size));
            const double sample_size = 0.5 * exp(2.0 * z / 3.0);
            double direction = 0.0;
            if (2 * relative_rank < size) direction = -1.0;
            else if (2 * relative_rank > size) direction = 1.0;
            const double spread = 0.5 * sqrt(
                z * sample_size * ((double)size - sample_size) / (double)size
            ) * direction;
            const double lower_estimate = (double)target
                - (double)relative_rank * sample_size / (double)size + spread;
            const double upper_estimate = (double)target
                + (double)(size - relative_rank) * sample_size / (double)size + spread;

            int64_t sample_left_value = (int64_t)floor(lower_estimate);
            if (sample_left_value < (int64_t)left) sample_left_value = (int64_t)left;
            if (sample_left_value < (int64_t)target) sample_left_value = (int64_t)target;
            int64_t sample_right_value = (int64_t)ceil(upper_estimate);
            if (sample_right_value > (int64_t)right) sample_right_value = (int64_t)right;
            if (sample_right_value < (int64_t)target) sample_right_value = (int64_t)target;
            const size_t sample_left = (size_t)sample_left_value;
            const size_t sample_right = (size_t)sample_right_value;
            (void)select_kth(values, sample_left, sample_right, target);
        }

        const int64_t pivot = values[target];
        size_t less = left;
        size_t scan = left;
        size_t greater = right + 1;
        while (scan < greater) {
            if (values[scan] < pivot) {
                const int64_t temporary = values[less];
                values[less++] = values[scan];
                values[scan++] = temporary;
            } else if (values[scan] > pivot) {
                const int64_t temporary = values[--greater];
                values[greater] = values[scan];
                values[scan] = temporary;
            } else {
                ++scan;
            }
        }
        if (target < less) right = less - 1;
        else if (target >= greater) left = greater;
        else return pivot;
    }
}

int64_t floyd_rivest_select(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = input[0];
    const int64_t rank_value = input[1];
    if (count_value < 1 || count_value > MAX_VALUES || rank_value < 0 ||
        rank_value >= count_value || length != (size_t)count_value + 2) return -1;

    const size_t count = (size_t)count_value;
    int64_t values[MAX_VALUES];
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 2];
        if (value < 0 || value > INT32_MAX) return -1;
        for (size_t previous = 0; previous < index; ++previous) {
            if (values[previous] == value) return -1;
        }
        values[index] = value;
    }
    return select_kth(values, 0, count - 1, (size_t)rank_value);
}

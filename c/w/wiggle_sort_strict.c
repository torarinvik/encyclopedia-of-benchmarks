#include <stddef.h>
#include <stdint.h>
#define MAX_ARRAY_LENGTH 4096

static int64_t select_kth(int64_t *values, size_t count, size_t target) {
    ptrdiff_t low = 0;
    ptrdiff_t high = (ptrdiff_t)count - 1;
    while (low < high) {
        ptrdiff_t left = low;
        ptrdiff_t right = high;
        int64_t pivot = values[(size_t)((left + right + 1) / 2)];
        while (left <= right) {
            while (left <= right && values[left] < pivot) ++left;
            while (left <= right && values[right] > pivot) --right;
            if (left <= right) {
                int64_t temporary = values[left];
                values[left] = values[right];
                values[right] = temporary;
                ++left;
                --right;
            }
        }
        if ((ptrdiff_t)target <= right) high = right;
        else if ((ptrdiff_t)target >= left) low = left;
        else break;
    }
    return values[target];
}

int64_t wiggle_sort_strict(const int64_t *input, size_t length,
                               uint8_t *output, size_t output_capacity) {
    if (length > MAX_ARRAY_LENGTH || (length != 0 && input == NULL)) return -1;
    int64_t values[MAX_ARRAY_LENGTH];

    for (size_t i = 0; i < length; ++i) {
        if (input[i] < INT32_MIN || input[i] > INT32_MAX) return -1;
        values[i] = input[i];
    }
    size_t bytes = length * 4;
    if (output_capacity < bytes || (bytes != 0 && output == NULL)) return -2;
    if (length == 0) return 0;

    int64_t median = select_kth(values, length, length / 2);
    size_t median_count = 0;
    int64_t smallest_value = values[0];
    for (size_t i = 0; i < length; ++i) {
        if (values[i] == median) ++median_count;
        if (values[i] < smallest_value) smallest_value = values[i];
    }
    size_t maximum_medians = (length + 1) / 2;
    if (median_count > maximum_medians
        || (length % 2 == 1 && median_count == maximum_medians && smallest_value != median))
        return -1;

    ptrdiff_t i = 0, j = 0, k = (ptrdiff_t)length - 1;
    ptrdiff_t modulus = (ptrdiff_t)length + 1 - (ptrdiff_t)(length % 2);
    while (j <= k) {
        ptrdiff_t mapped_j = (2 * j + 1) % modulus;
        if (values[mapped_j] > median) {
            ptrdiff_t mapped_i = (2 * i + 1) % modulus;
            int64_t temporary = values[mapped_j];
            values[mapped_j] = values[mapped_i];
            values[mapped_i] = temporary;
            ++i;
            ++j;
        } else if (values[mapped_j] < median) {
            ptrdiff_t mapped_k = (2 * k + 1) % modulus;
            int64_t temporary = values[mapped_j];
            values[mapped_j] = values[mapped_k];
            values[mapped_k] = temporary;
            --k;
        } else {
            ++j;
        }
    }
    for (size_t i = 0; i < length; ++i) {
        uint32_t bits = (uint32_t)(int32_t)values[i];
        for (size_t byte = 0; byte < 4; ++byte)
            output[i * 4 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)length;
}

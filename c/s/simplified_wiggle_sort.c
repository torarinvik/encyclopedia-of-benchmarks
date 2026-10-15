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

int64_t simplified_wiggle_sort(const int64_t *input, size_t length,
                               uint8_t *output, size_t output_capacity) {
    if (length > MAX_ARRAY_LENGTH || (length != 0 && input == NULL)) return -1;
    int64_t values[MAX_ARRAY_LENGTH];
    int64_t ordered[MAX_ARRAY_LENGTH];
    for (size_t i = 0; i < length; ++i) {
        if (input[i] < INT32_MIN || input[i] > INT32_MAX) return -1;
        values[i] = input[i];
    }
    size_t bytes = length * 4;
    if (output_capacity < bytes || (bytes != 0 && output == NULL)) return -2;
    if (length == 0) return 0;

    int64_t median = select_kth(values, length, length / 2);
    size_t smaller = 0;
    ptrdiff_t greater = (ptrdiff_t)(length - 1 - (length % 2));
    for (size_t i = 0; i < length; ++i) {
        if (values[i] > median) {
            ordered[greater] = values[i];
            greater -= 2;
        } else if (smaller < length) {
            ordered[smaller] = values[i];
            smaller += 2;
        } else {
            ordered[greater] = values[i];
            greater -= 2;
        }
    }
    for (size_t i = 0; i < length; ++i) {
        uint32_t bits = (uint32_t)(int32_t)ordered[i];
        for (size_t byte = 0; byte < 4; ++byte)
            output[i * 4 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)length;
}

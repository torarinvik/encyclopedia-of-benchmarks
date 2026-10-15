/* Count strict inversions with bottom-up merge sort. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t count_inversions(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return -1;
    if (length < 2) return 0;

    int64_t source[MAX_LENGTH];
    int64_t scratch[MAX_LENGTH];
    for (size_t i = 0; i < length; ++i) source[i] = values[i];

    int64_t inversions = 0;
    for (size_t width = 1; width < length; width *= 2) {
        for (size_t low = 0; low < length;) {
            size_t middle = low + width;
            if (middle > length) middle = length;
            size_t high = middle + width;
            if (high > length) high = length;
            size_t left = low, right = middle, out = low;
            while (left < middle && right < high) {
                if (source[left] <= source[right]) {
                    scratch[out++] = source[left++];
                } else {
                    scratch[out++] = source[right++];
                    inversions += (int64_t)(middle - left);
                }
            }
            while (left < middle) scratch[out++] = source[left++];
            while (right < high) scratch[out++] = source[right++];
            low = high;
        }
        for (size_t i = 0; i < length; ++i) source[i] = scratch[i];
    }
    return inversions;
}

/* Length of the longest arithmetic subsequence. */
#include <stddef.h>
#include <stdint.h>

int64_t longest_arithmetic_subsequence(const int64_t *values, size_t length)
{
    if (length > 64 || (length != 0 && values == NULL)) return -1;
    for (size_t i = 0; i < length; ++i)
        if (values[i] < -1000000 || values[i] > 1000000) return -1;
    if (length <= 1) return (int64_t)length;

    int64_t keys[64][127] = {{0}};
    int64_t sizes[64][127] = {{0}};
    int64_t maximum = 2;
    for (size_t right = 0; right < length; ++right) {
        for (size_t left = 0; left < right; ++left) {
            const int64_t difference = values[right] - values[left];
            size_t slot = (size_t)((difference % 127 + 127) % 127);
            while (sizes[left][slot] != 0 && keys[left][slot] != difference)
                slot = (slot + 1) % 127;
            const int64_t candidate = (sizes[left][slot] == 0 ? 1 : sizes[left][slot]) + 1;

            slot = (size_t)((difference % 127 + 127) % 127);
            while (sizes[right][slot] != 0 && keys[right][slot] != difference)
                slot = (slot + 1) % 127;
            if (sizes[right][slot] == 0 || candidate > sizes[right][slot]) {
                keys[right][slot] = difference;
                sizes[right][slot] = candidate;
            }
            if (candidate > maximum) maximum = candidate;
        }
    }
    return maximum;
}

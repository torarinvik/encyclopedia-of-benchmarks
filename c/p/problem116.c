/* Count single-color block replacements for lengths two, three, and four. */
#include <stdint.h>

#define MAX_LENGTH INT64_C(91)
#define WAY_COUNT 276

int64_t problem116(int64_t length)
{
    if (length > MAX_LENGTH) return -1;
    if (length < 0) return -1;
    int64_t ways[WAY_COUNT] = {0};
    for (int64_t row_length = 0; row_length <= length; ++row_length) {
        for (int64_t tile_length = 2; tile_length < 5; ++tile_length) {
            const int64_t color = tile_length - 2;
            for (int64_t tile_start = 0; tile_start < row_length - tile_length + 1; ++tile_start) {
                const int64_t suffix = row_length - tile_start - tile_length;
                ways[row_length * 3 + color] += ways[suffix * 3 + color] + 1;
            }
        }
    }
    return ways[length * 3] + ways[length * 3 + 1] + ways[length * 3 + 2];
}

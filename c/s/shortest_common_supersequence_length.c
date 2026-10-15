/* Return the shortest common supersequence length of two packed ASCII sequences. */
#include <stddef.h>
#include <stdint.h>

int64_t shortest_common_supersequence_length(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > 512) return -1;
    const int64_t left_length = packed[0];
    const int64_t right_length = packed[1];
    if (left_length < 0 || left_length > 255 || right_length < 0 || right_length > 255 ||
        length != (size_t)(2 + left_length + right_length)) return -1;
    for (size_t index = 0; index < (size_t)(left_length + right_length); ++index) {
        if (packed[2 + index] < 0 || packed[2 + index] > 127) return -1;
    }

    const size_t rows = (size_t)left_length + 1;
    const size_t columns = (size_t)right_length + 1;
    int64_t table[256 * 256] = {0};
    for (size_t i = 1; i < rows; ++i) {
        for (size_t j = 1; j < columns; ++j) {
            const size_t cell = i * columns + j;
            if (packed[1 + i] == packed[1 + (size_t)left_length + j]) {
                table[cell] = table[(i - 1) * columns + j - 1] + 1;
            } else {
                const int64_t above = table[(i - 1) * columns + j];
                const int64_t left = table[i * columns + j - 1];
                table[cell] = above > left ? above : left;
            }
        }
    }
    return left_length + right_length - table[(rows - 1) * columns + columns - 1];
}

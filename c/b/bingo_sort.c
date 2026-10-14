#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 1024

void bingo_sort(int64_t *values, size_t length)
{
    if (length > MAX_VALUES || length < 2) return;
    int64_t bingo = values[0];
    for (size_t index = 1; index < length; ++index) {
        if (values[index] < bingo) bingo = values[index];
    }
    size_t next_position = 0;
    while (next_position < length) {
        int has_next = 0;
        int64_t next_bingo = 0;
        for (size_t index = next_position; index < length; ++index) {
            if (values[index] == bingo) {
                const int64_t temporary = values[index];
                values[index] = values[next_position];
                values[next_position] = temporary;
                ++next_position;
            } else if (!has_next || values[index] < next_bingo) {
                next_bingo = values[index];
                has_next = 1;
            }
        }
        if (next_position == length) break;
        bingo = next_bingo;
    }
}

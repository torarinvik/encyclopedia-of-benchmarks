/* Count stones whose ASCII byte appears in the unique-jewel set. */
#include <stddef.h>
#include <stdint.h>

#define MAX_JEWELS_LENGTH 127
#define MAX_STONES_LENGTH 4096
#define MAX_PACKED_LENGTH (2 + MAX_JEWELS_LENGTH + MAX_STONES_LENGTH)

int64_t jewels_and_stones(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_PACKED_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_JEWELS_LENGTH ||
        input[1] < 0 || input[1] > MAX_STONES_LENGTH) return -1;
    const size_t jewel_count = (size_t)input[0];
    const size_t stone_count = (size_t)input[1];
    if (length != 2 + jewel_count + stone_count) return -1;
    int64_t counts[128] = {0};
    for (size_t index = 0; index < jewel_count; ++index) {
        const int64_t value = input[2 + index];
        if (value < 1 || value > 127 || counts[value] != 0) return -1;
        counts[value] = 1;
    }
    int64_t total = 0;
    const size_t stone_start = 2 + jewel_count;
    for (size_t index = 0; index < stone_count; ++index) {
        const int64_t value = input[stone_start + index];
        if (value < 1 || value > 127) return -1;
        total += counts[value];
    }
    return total;
}

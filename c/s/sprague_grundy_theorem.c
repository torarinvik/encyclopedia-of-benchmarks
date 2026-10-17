/* Compute a bounded single-heap subtraction game's Sprague-Grundy number. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_POSITION = 64, MAX_MOVE_COUNT = 32, MAX_MOVE_SIZE = 32 };

static int64_t calculate_grundy(int64_t position, int64_t memo[MAX_POSITION + 1],
                                const int64_t *values, size_t move_count)
{
    const size_t index = (size_t)position;
    if (memo[index] != -1) return memo[index];
    if (position == 0) {
        memo[0] = 0;
        return 0;
    }

    uint8_t reachable[MAX_MOVE_COUNT + 1] = {0};
    for (size_t i = 0; i < move_count; ++i) {
        const int64_t move = values[2 + i];
        if (move <= position) {
            const int64_t child = calculate_grundy(position - move, memo, values, move_count);
            if (child >= 0 && child <= MAX_MOVE_COUNT) reachable[(size_t)child] = 1;
        }
    }
    int64_t mex = 0;
    while (mex <= MAX_MOVE_COUNT && reachable[(size_t)mex]) ++mex;
    memo[index] = mex;
    return mex;
}

int64_t sprague_grundy_theorem(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 2 + MAX_MOVE_COUNT) return -1;
    const int64_t position = values[0];
    const int64_t move_count_value = values[1];
    if (position < 0 || position > MAX_POSITION ||
        move_count_value < 0 || move_count_value > MAX_MOVE_COUNT) return -1;
    const size_t move_count = (size_t)move_count_value;
    if (length != 2 + move_count) return -1;
    for (size_t i = 0; i < move_count; ++i)
        if (values[2 + i] < 1 || values[2 + i] > MAX_MOVE_SIZE) return -1;

    int64_t memo[MAX_POSITION + 1];
    for (size_t i = 0; i <= MAX_POSITION; ++i) memo[i] = -1;
    return calculate_grundy(position, memo, values, move_count);
}

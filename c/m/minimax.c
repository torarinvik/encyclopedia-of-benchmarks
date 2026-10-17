#include <stddef.h>
#include <stdint.h>

#define MINIMAX_MAX_LEAVES 32
#define MINIMAX_MAX_INPUT_LENGTH (2 + MINIMAX_MAX_LEAVES)
#define MINIMAX_I32_MIN (-2147483647LL - 1)
#define MINIMAX_I32_MAX 2147483647LL
#define MINIMAX_INVALID_RESULT (-2147483649LL)

static int64_t minimax_evaluate(const int64_t *values, size_t index, size_t depth,
                                size_t height, int maximizing) {
    if (depth == height) return values[2 + index];
    const int64_t left = minimax_evaluate(values, index * 2, depth + 1, height, !maximizing);
    const int64_t right = minimax_evaluate(values, index * 2 + 1, depth + 1, height, !maximizing);
    if (maximizing) return left > right ? left : right;
    return left < right ? left : right;
}

int64_t minimax(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MINIMAX_MAX_INPUT_LENGTH) return MINIMAX_INVALID_RESULT;
    const int64_t leaf_count = values[0];
    const int64_t first_turn_is_max = values[1];
    if (leaf_count < 1 || leaf_count > MINIMAX_MAX_LEAVES ||
        (leaf_count & (leaf_count - 1)) != 0 || (first_turn_is_max != 0 && first_turn_is_max != 1) ||
        length != (size_t)(2 + leaf_count)) return MINIMAX_INVALID_RESULT;
    for (int64_t leaf = 0; leaf < leaf_count; ++leaf)
        if (values[2 + leaf] < MINIMAX_I32_MIN || values[2 + leaf] > MINIMAX_I32_MAX)
            return MINIMAX_INVALID_RESULT;

    size_t height = 0;
    for (int64_t width = leaf_count; width > 1; width /= 2) ++height;
    return minimax_evaluate(values, 0, 0, height, first_turn_is_max == 1);
}

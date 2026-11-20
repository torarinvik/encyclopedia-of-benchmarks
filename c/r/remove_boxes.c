#include <stddef.h>
#include <stdint.h>

#define MAX_BOXES 18
#define MAX_PARSEABLE_LENGTH (MAX_BOXES + 2)
#define MAX_MEMO (MAX_BOXES * MAX_BOXES * (MAX_BOXES + 1))

static int64_t solve_boxes(size_t left, size_t right, size_t carry,
                           const int64_t *colors, const size_t *counts,
                           int64_t *memo) {
    if (left > right) {
        return 0;
    }
    const size_t index = (left * MAX_BOXES + right) * (MAX_BOXES + 1) + carry;
    if (memo[index] >= 0) {
        return memo[index];
    }

    const size_t attached = counts[left] + carry;
    const int64_t group_score = (int64_t)(attached * attached);
    int64_t best = group_score + solve_boxes(left + 1, right, 0, colors, counts, memo);
    for (size_t later = left + 1; later <= right; ++later) {
        if (colors[later] == colors[left]) {
            const int64_t joined = solve_boxes(left + 1, later - 1, 0, colors, counts, memo)
                + solve_boxes(later, right, attached, colors, counts, memo);
            if (joined > best) {
                best = joined;
            }
        }
    }
    memo[index] = best;
    return best;
}

int64_t remove_boxes(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) {
        return -1;
    }
    const int64_t n_raw = values[0];
    if (n_raw < 0 || n_raw > MAX_BOXES || length != (size_t)n_raw + 1) {
        return -1;
    }
    const size_t n = (size_t)n_raw;
    int64_t colors[MAX_BOXES] = {0};
    size_t counts[MAX_BOXES] = {0};
    size_t groups = 0;
    for (size_t index = 0; index < n; ++index) {
        const int64_t color = values[index + 1];
        if (color < 0 || color > 7) {
            return -1;
        }
        if (groups != 0 && colors[groups - 1] == color) {
            ++counts[groups - 1];
        } else {
            colors[groups] = color;
            counts[groups] = 1;
            ++groups;
        }
    }
    if (groups == 0) {
        return 0;
    }

    int64_t memo[MAX_MEMO];
    for (size_t index = 0; index < MAX_MEMO; ++index) {
        memo[index] = -1;
    }
    return solve_boxes(0, groups - 1, 0, colors, counts, memo);
}

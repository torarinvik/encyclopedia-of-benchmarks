/* Maximize one repeated binary answer while changing at most k entries. */
#include <stddef.h>
#include <stdint.h>

#define MAX_BITS 1024

static size_t longest_for_target(const int64_t *input, size_t count,
                                 size_t allowed, int64_t target)
{
    size_t left = 0;
    size_t opposite = 0;
    size_t best = 0;
    for (size_t right = 0; right < count; ++right) {
        if (input[right + 1] != target) ++opposite;
        while (opposite > allowed) {
            if (input[left + 1] != target) --opposite;
            ++left;
        }
        size_t window = right - left + 1;
        if (window > best) best = window;
    }
    return best;
}

int64_t max_consecutive_answers(const int64_t *input, size_t length)
{
    if (input == NULL || length == 0 || length > MAX_BITS + 1) return -1;
    size_t count = length - 1;
    if (input[0] < 0 || input[0] > (int64_t)count) return -1;
    for (size_t i = 0; i < count; ++i)
        if (input[i + 1] != 0 && input[i + 1] != 1) return -1;
    size_t allowed = (size_t)input[0];
    size_t true_target = longest_for_target(input, count, allowed, 1);
    size_t false_target = longest_for_target(input, count, allowed, 0);
    return (int64_t)(true_target > false_target ? true_target : false_target);
}

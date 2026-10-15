/* Memoized endpoint recurrence, evaluated bottom-up from right to left. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t longest_valid_parentheses(const int64_t *input, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] != 40 && input[index] != 41) return -1;

    size_t end_exclusive[MAX_LENGTH] = {0};
    size_t best = 0;
    for (size_t remaining = length; remaining > 0; --remaining) {
        const size_t index = remaining - 1;
        if (input[index] == 40) {
            if (index + 1 < length && input[index + 1] == 41) {
                end_exclusive[index] = index + 2;
                if (index + 2 < length && end_exclusive[index + 2] > end_exclusive[index])
                    end_exclusive[index] = end_exclusive[index + 2];
            } else if (index + 1 < length) {
                const size_t nested_end = end_exclusive[index + 1];
                if (nested_end > 0 && nested_end < length && input[nested_end] == 41) {
                    end_exclusive[index] = nested_end + 1;
                    if (nested_end + 1 < length &&
                        end_exclusive[nested_end + 1] > end_exclusive[index])
                        end_exclusive[index] = end_exclusive[nested_end + 1];
                }
            }
        }
        if (end_exclusive[index] > index && end_exclusive[index] - index > best)
            best = end_exclusive[index] - index;
    }
    return (int64_t)best;
}

/* Stack of unmatched opening positions for longest valid parentheses. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t longest_valid_parentheses_stack(const int64_t *input, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] != 40 && input[index] != 41) return -1;

    /* The sentinel is the index before the current unmatched segment. */
    ptrdiff_t unmatched[MAX_LENGTH + 1];
    size_t top = 0;
    unmatched[top] = -1;
    size_t best = 0;
    for (size_t index = 0; index < length; ++index) {
        if (input[index] == 40) {
            unmatched[++top] = (ptrdiff_t)index;
        } else {
            if (top == 0) {
                unmatched[0] = (ptrdiff_t)index;
            } else {
                --top;
                const size_t current = (size_t)((ptrdiff_t)index - unmatched[top]);
                if (current > best) best = current;
            }
        }
    }
    return (int64_t)best;
}

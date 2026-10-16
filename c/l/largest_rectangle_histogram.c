/* Largest rectangle area in a bounded histogram. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 64
#define MAX_HEIGHT 1000000LL
#define INVALID_RESULT INT64_MIN

int64_t largest_rectangle_histogram(const int64_t *heights, size_t length)
{
    if (length == 0) return 0;
    if (heights == NULL || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    for (size_t index = 0; index < length; ++index) {
        if (heights[index] < 0 || heights[index] > MAX_HEIGHT) return INVALID_RESULT;
    }

    size_t stack[MAX_INPUT_LENGTH];
    size_t top = 0;
    int64_t best = 0;
    for (size_t index = 0; index < length; ++index) {
        while (top > 0 && heights[stack[top - 1]] > heights[index]) {
            const size_t bar = stack[--top];
            const size_t left = top == 0 ? 0 : stack[top - 1] + 1;
            const int64_t area = heights[bar] * (int64_t)(index - left);
            best = best > area ? best : area;
        }
        stack[top++] = index;
    }
    while (top > 0) {
        const size_t bar = stack[--top];
        const size_t left = top == 0 ? 0 : stack[top - 1] + 1;
        const int64_t area = heights[bar] * (int64_t)(length - left);
        best = best > area ? best : area;
    }
    return best;
}

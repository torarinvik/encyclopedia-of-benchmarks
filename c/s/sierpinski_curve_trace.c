#include <stddef.h>
#include <stdint.h>

enum { MAX_ORDER = 2, MAX_PARSEABLE_INPUT = 2, MAX_STACK = 64 };

typedef struct {
    uint8_t symbol;
    uint8_t level;
} Frame;

static void push(Frame stack[MAX_STACK], size_t *top, uint8_t symbol, uint8_t level) {
    stack[*top].symbol = symbol;
    stack[*top].level = level;
    ++*top;
}

static size_t emit_curve(uint8_t order, uint8_t *output) {
    Frame stack[MAX_STACK];
    size_t top = 0;
    size_t written = 0;
    push(stack, &top, 5, 0);          /* outer direction 1 */
    push(stack, &top, 3, order);      /* D */
    push(stack, &top, 7, 0);          /* outer direction 3 */
    push(stack, &top, 2, order);      /* C */
    push(stack, &top, 9, 0);          /* outer direction 5 */
    push(stack, &top, 1, order);      /* B */
    push(stack, &top, 11, 0);         /* outer direction 7 */
    push(stack, &top, 0, order);      /* A */

    while (top != 0) {
        const Frame frame = stack[--top];
        if (frame.symbol >= 4) {
            output[written++] = (uint8_t)(frame.symbol - 4);
            continue;
        }
        if (frame.level == 0) continue;
        const uint8_t child = (uint8_t)(frame.level - 1);
        switch (frame.symbol) {
            case 0: /* A,7,B,8,D,1,A */
                push(stack, &top, 0, child); push(stack, &top, 5, 0);
                push(stack, &top, 3, child); push(stack, &top, 12, 0);
                push(stack, &top, 1, child); push(stack, &top, 11, 0);
                push(stack, &top, 0, child); break;
            case 1: /* B,5,C,14,A,7,B */
                push(stack, &top, 1, child); push(stack, &top, 11, 0);
                push(stack, &top, 0, child); push(stack, &top, 18, 0);
                push(stack, &top, 2, child); push(stack, &top, 9, 0);
                push(stack, &top, 1, child); break;
            case 2: /* C,3,D,12,B,5,C */
                push(stack, &top, 2, child); push(stack, &top, 9, 0);
                push(stack, &top, 1, child); push(stack, &top, 16, 0);
                push(stack, &top, 3, child); push(stack, &top, 7, 0);
                push(stack, &top, 2, child); break;
            default: /* D,1,A,10,C,3,D */
                push(stack, &top, 3, child); push(stack, &top, 7, 0);
                push(stack, &top, 2, child); push(stack, &top, 14, 0);
                push(stack, &top, 0, child); push(stack, &top, 5, 0);
                push(stack, &top, 3, child); break;
        }
    }
    return written;
}

int64_t sierpinski_curve_trace(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length == 0 || length > MAX_PARSEABLE_INPUT) return -1;
    if (length != 1 || input[0] < 0 || input[0] > MAX_ORDER) return -1;
    const size_t order = (size_t)input[0];
    size_t required = 4;
    for (size_t i = 0; i < order; ++i) required *= 4;
    if (output == NULL || capacity < required) return -2;
    return (int64_t)emit_curve((uint8_t)order, output);
}

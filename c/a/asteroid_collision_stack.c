#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_INPUT = 66 };

int64_t asteroid_collision_stack(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT) return -1;
    const int64_t n_word = input[0];
    if (n_word < 0 || n_word > MAX_N || length != (size_t)n_word + 1) return -1;

    int8_t stack[MAX_N];
    size_t top = 0;
    for (size_t i = 0; i < (size_t)n_word; ++i) {
        const int64_t value = input[i + 1];
        if (value == 0 || value < -127 || value > 127) return -1;
        const int8_t incoming = (int8_t)value;
        int alive = 1;
        while (alive && top > 0 && stack[top - 1] > 0 && incoming < 0) {
            const int positive_size = stack[top - 1];
            const int negative_size = -(int)incoming;
            if (positive_size < negative_size) --top;
            else if (positive_size == negative_size) { --top; alive = 0; }
            else alive = 0;
        }
        if (alive) stack[top++] = incoming;
    }

    const size_t required = top + 1;
    if (output == NULL || capacity < required) return -2;
    output[0] = (uint8_t)top;
    for (size_t i = 0; i < top; ++i) output[i + 1] = (uint8_t)stack[i];
    return (int64_t)required;
}

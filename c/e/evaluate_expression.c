#include <stddef.h>
#include <stdint.h>

static void put32(uint8_t *out, uint32_t value) {
    for (size_t i = 0; i < 4; ++i) out[i] = (uint8_t)(value >> (8 * i));
}

static void put_f64(uint8_t *out, double value) {
    union { double f; uint64_t u; } bits = { .f = value };
    for (size_t i = 0; i < 8; ++i) out[4 + i] = (uint8_t)(bits.u >> (8 * i));
}

int64_t evaluate_expression(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 131) return -1;
    int64_t count = input[0];
    if (count < 1 || count > 64 || length != (size_t)(1 + 2 * count)) return -1;
    double stack[64];
    size_t depth = 0;
    int valid = 1;
    for (int64_t i = 0; i < count; ++i) {
        int64_t op = input[1 + 2 * i], payload = input[2 + 2 * i];
        if (op == 0) {
            if (payload < -1000000000 || payload > 1000000000) return -1;
            stack[depth++] = (double)payload / 1000.0;
        } else if (op >= 1 && op <= 4) {
            if (payload != 0) return -1;
            if (depth < 2) { valid = 0; break; }
            double right = stack[--depth], left = stack[--depth];
            if (op == 1) stack[depth++] = left + right;
            else if (op == 2) stack[depth++] = left - right;
            else if (op == 3) stack[depth++] = left * right;
            else if (right == 0.0) { valid = 0; break; }
            else stack[depth++] = left / right;
        } else { valid = 0; break; }
    }
    valid = valid && depth == 1;
    size_t needed = valid ? 12 : 4;
    if (output == NULL || capacity < needed) return -2;
    put32(output, valid ? 1u : 0u);
    if (valid) put_f64(output, stack[0]);
    return (int64_t)needed;
}

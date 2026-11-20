#include <stddef.h>
#include <stdint.h>

enum { MAX_STATES = 8, MAX_STEPS = 64, MAX_INPUT = 267, MAX_OUTPUT = 65 };

int64_t metropolis_hastings_asymmetric_proposal(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], steps64 = input[1], initial64 = input[2];
    if (n64 < 2 || n64 > MAX_STATES || steps64 < 0 || steps64 > MAX_STEPS ||
        initial64 < 0 || initial64 >= n64) return -1;
    const size_t n = (size_t)n64, steps = (size_t)steps64;
    const size_t weights_start = 3;
    const size_t matrix_start = weights_start + n;
    const size_t proposal_start = matrix_start + n * n;
    const size_t draw_start = proposal_start + steps;
    if (length != draw_start + 2 * steps) return -1;

    for (size_t state = 0; state < n; ++state) {
        const int64_t weight = input[weights_start + state];
        if (weight < 1 || weight > 1024) return -1;
    }
    for (size_t source = 0; source < n; ++source) {
        int64_t row_sum = 0;
        for (size_t dest = 0; dest < n; ++dest) {
            const int64_t q = input[matrix_start + source * n + dest];
            if (q < 0 || q > 1024) return -1;
            row_sum += q;
        }
        if (row_sum != 1024) return -1;
    }

    uint8_t trace[MAX_OUTPUT];
    size_t current = (size_t)initial64;
    trace[0] = (uint8_t)current;
    for (size_t step = 0; step < steps; ++step) {
        const int64_t proposal64 = input[proposal_start + step];
        const int64_t draw_num = input[draw_start + 2 * step];
        const int64_t draw_den = input[draw_start + 2 * step + 1];
        if (proposal64 < 0 || proposal64 >= n64 || draw_den < 1 || draw_den > 1024 ||
            draw_num < 0 || draw_num >= draw_den) return -1;
        const size_t proposal = (size_t)proposal64;
        const int64_t forward = input[matrix_start + current * n + proposal];
        if (forward == 0) return -1;
        const int64_t reverse = input[matrix_start + proposal * n + current];
        const int64_t numerator = input[weights_start + proposal] * reverse;
        const int64_t denominator = input[weights_start + current] * forward;
        if (numerator >= denominator || draw_num * denominator < draw_den * numerator)
            current = proposal;
        trace[step + 1] = (uint8_t)current;
    }

    const size_t needed = steps + 1;
    if (output == NULL || capacity < needed) return -2;
    for (size_t i = 0; i < needed; ++i) output[i] = trace[i];
    return (int64_t)needed;
}

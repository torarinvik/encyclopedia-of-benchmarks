/* Independently authored draft; not compiled or run. */
#include <stddef.h>
#include <stdint.h>

int64_t circle_line_intersection_symbolic(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (!input || length != 6) return -1;
    for (size_t i = 0; i < 6; ++i)
        if (input[i] < -1000 || input[i] > 1000) return -1;
    const int64_t x = input[0], y = input[1], r = input[2];
    const int64_t a = input[3], b = input[4], c = input[5];
    if (r < 1 || (a == 0 && b == 0)) return -1;
    const int64_t d = a*a + b*b, q = a*x + b*y + c;
    const int64_t h = r*r*d - q*q;
    const int64_t words[7] = {h < 0 ? 0 : h == 0 ? 1 : 2,
                              x*d-a*q, y*d-b*q, d, -b, a, h};
    const size_t count = h < 0 ? 1 : 7, needed = count * 8;
    if (!output || capacity < needed) return -2;
    for (size_t i = 0; i < count; ++i) {
        const uint64_t bits = (uint64_t)words[i];
        for (size_t j = 0; j < 8; ++j) output[8*i+j] = (uint8_t)(bits >> (8*j));
    }
    return (int64_t)needed;
}

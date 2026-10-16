#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define LIMIT INT64_C(1000000)
#define INVALID_RESULT INT64_C(-1)

static void write_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t cramers_rule_2x2(const int64_t *v, size_t length, uint8_t *output, size_t capacity) {
    if (v == NULL || length != 6) return -1;
    for (size_t i = 0; i < 6; ++i) if (v[i] < -LIMIT || v[i] > LIMIT) return -1;
    const int64_t a1=v[0], b1=v[1], c1=v[2], a2=v[3], b2=v[4], c2=v[5];
    const int64_t d=a1*b2-a2*b1, dx=c1*b2-c2*b1, dy=a1*c2-a2*c1;
    if (d == 0) return INVALID_RESULT;
    if (output == NULL || capacity < 16) return -2;
    write_f64_le(output, 0, (double)dx / (double)d);
    write_f64_le(output, 8, (double)dy / (double)d);
    return 2;
}

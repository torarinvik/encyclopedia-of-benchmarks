#include <stddef.h>
#include <stdint.h>
#include <string.h>

static uint16_t get16(const uint8_t *p, size_t i) { return (uint16_t)p[i] | ((uint16_t)p[i + 1] << 8); }
static void put16(uint8_t *p, size_t i, size_t x) { p[i] = (uint8_t)x; p[i + 1] = (uint8_t)(x >> 8); }
static int op(int64_t x) { return x == 43 || x == 45 || x == 42 || x == 47 || x == 94; }
int64_t postfix_to_infix(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
    if (!v || n < 1 || n > 65 || v[0] < 0 || v[0] > 64 || n != (size_t)v[0] + 1) return -1;
    if (!out || cap < 8192) return -2;
    size_t count = (size_t)v[0], stack = 0, scratch = 256;
    if (!count) return 0;
    if (count == 1) {
        int64_t x = v[1]; if (!((x >= 'A' && x <= 'Z') || (x >= 'a' && x <= 'z'))) return -1;
        out[0] = (uint8_t)x; return 1;
    }
    for (size_t i = 0; i < count; ++i) {
        int64_t x = v[i + 1];
        if (op(x)) {
            if (stack < 2) return -1;
            size_t left_slot = stack - 2, right_slot = stack - 1;
            size_t ls = get16(out, left_slot * 4), ll = get16(out, left_slot * 4 + 2);
            size_t rs = get16(out, right_slot * 4), rl = get16(out, right_slot * 4 + 2);
            size_t start = scratch; out[scratch++] = '(';
            memcpy(out + scratch, out + ls, ll); scratch += ll; out[scratch++] = (uint8_t)x;
            memcpy(out + scratch, out + rs, rl); scratch += rl; out[scratch++] = ')';
            put16(out, left_slot * 4, start); put16(out, left_slot * 4 + 2, scratch - start); --stack;
        } else {
            if (!((x >= 'A' && x <= 'Z') || (x >= 'a' && x <= 'z'))) return -1;
            size_t slot = stack++; out[scratch] = (uint8_t)x;
            put16(out, slot * 4, scratch++); put16(out, slot * 4 + 2, 1);
        }
        if (scratch > cap) return -2;
    }
    if (stack != 1) return -1;
    size_t start = get16(out, 0), len = get16(out, 2);
    memmove(out, out + start, len); return (int64_t)len;
}

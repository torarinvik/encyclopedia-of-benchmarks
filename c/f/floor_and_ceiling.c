#include <stddef.h>
#include <stdint.h>

#define MAX_N 127
#define MIN_VALUE (-1000000)
#define MAX_VALUE 1000000
#define NO_VALUE INT64_MIN
static void put_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[offset+b] = (uint8_t)(bits >> (8*b));
}
int64_t floor_and_ceiling(const int64_t *in, size_t length, uint8_t *out, size_t capacity) {
    if (in == NULL || length < 3 || length > 3 + 3*MAX_N) return -1;
    int64_t raw_n = in[0], root = in[1], key = in[2];
    if (raw_n < 0 || raw_n > MAX_N || key < MIN_VALUE || key > MAX_VALUE || length != 3 + 3*(size_t)raw_n) return -1;
    size_t n = (size_t)raw_n;
    if (n == 0 ? root != -1 : (root < 0 || root >= raw_n)) return -1;
    int64_t floor = NO_VALUE, ceiling = NO_VALUE;
    size_t current = n;
    if (n != 0) current = (size_t)root;
    for (size_t steps = 0; current < n && steps < n; ++steps) {
        size_t base = 3 + 3*current;
        int64_t value = in[base], left = in[base+1], right = in[base+2];
        if (value < MIN_VALUE || value > MAX_VALUE || left < -1 || right < -1 || left >= raw_n || right >= raw_n) return -1;
        if (value == key) { floor = value; ceiling = value; break; }
        if (key < value) { ceiling = value; current = left < 0 ? n : (size_t)left; }
        else { floor = value; current = right < 0 ? n : (size_t)right; }
    }
    if (out == NULL || capacity < 16) return -2;
    put_i64_le(out, 0, floor); put_i64_le(out, 8, ceiling);
    return 16;
}

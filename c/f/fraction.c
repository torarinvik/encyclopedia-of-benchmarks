#include <stddef.h>
#include <stdint.h>

static int64_t gcd_pos(int64_t a, int64_t b) {
    if (a < 0) a = -a;
    if (b < 0) b = -b;
    while (b != 0) { int64_t r = a % b; a = b; b = r; }
    return a;
}
static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) out[at + i] = (uint8_t)(bits >> (8 * i));
}
int64_t fraction(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
    if (v == NULL || n != 4) return -1;
    int64_t n1=v[0], d1=v[1], n2=v[2], d2=v[3];
    if (n1 < -10000 || n1 > 10000 || n2 < -10000 || n2 > 10000 ||
        d1 < -1000 || d1 > 1000 || d2 < -1000 || d2 > 1000 || d1 == 0 || d2 == 0) return -1;
    if (out == NULL || cap < 16) return -2;
    int64_t g = gcd_pos(d1, d2);
    int64_t numerator = (d2 / g) * n1 + (d1 / g) * n2;
    int64_t denominator = (d1 / g) * d2;
    int64_t reduce = gcd_pos(numerator, denominator);
    numerator /= reduce;
    denominator /= reduce;
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
    put_i64(out, 0, numerator);
    put_i64(out, 8, denominator);
    return 16;
}

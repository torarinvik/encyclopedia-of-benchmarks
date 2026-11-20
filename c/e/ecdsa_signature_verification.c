#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

typedef struct { bool infinity; int64_t x, y; } Point;

static int64_t modp(int64_t value, int64_t modulus) {
    int64_t result = value % modulus;
    return result < 0 ? result + modulus : result;
}

static int64_t inverse(int64_t value, int64_t modulus) {
    int64_t old_r = modulus, r = modp(value, modulus);
    int64_t old_t = 0, t = 1;
    while (r != 0) {
        int64_t quotient = old_r / r;
        int64_t next_r = old_r - quotient * r;
        int64_t next_t = old_t - quotient * t;
        old_r = r; r = next_r;
        old_t = t; t = next_t;
    }
    return old_r == 1 ? modp(old_t, modulus) : 0;
}

static Point infinity(void) { return (Point){true, 0, 0}; }

static Point add(Point left, Point right) {
    if (left.infinity) return right;
    if (right.infinity) return left;
    if (left.x == right.x && modp(left.y + right.y, 17) == 0) return infinity();
    int64_t numerator, denominator;
    if (left.x == right.x && left.y == right.y) {
        numerator = modp(3 * left.x * left.x + 2, 17);
        denominator = modp(2 * left.y, 17);
    } else {
        numerator = modp(right.y - left.y, 17);
        denominator = modp(right.x - left.x, 17);
    }
    int64_t slope = modp(numerator * inverse(denominator, 17), 17);
    int64_t x = modp(slope * slope - left.x - right.x, 17);
    int64_t y = modp(slope * (left.x - x) - left.y, 17);
    return (Point){false, x, y};
}

static Point multiply(Point point, int64_t scalar) {
    Point result = infinity();
    while (scalar > 0) {
        if ((scalar & 1) != 0) result = add(result, point);
        scalar >>= 1;
        if (scalar > 0) point = add(point, point);
    }
    return result;
}

static bool on_curve(Point point) {
    return modp(point.y * point.y - point.x * point.x * point.x - 2 * point.x - 2, 17) == 0;
}

int64_t ecdsa_signature_verification(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length != 11) return -1;
    int64_t p=input[0], a=input[1], b=input[2], gx=input[3], gy=input[4], n=input[5];
    int64_t qx=input[6], qy=input[7], digest=input[8], r=input[9], s=input[10];
    if (p != 17 || a != 2 || b != 2 || gx != 5 || gy != 1 || n != 19) return -1;
    if (modp(4*a*a*a + 27*b*b, p) == 0) return -1;
    if (qx < 0 || qx >= p || qy < 0 || qy >= p) return -1;
    if (digest < 0 || digest > 31 || r < 1 || r >= n || s < 1 || s >= n) return -1;
    Point base = {false, gx, gy}, public_key = {false, qx, qy};
    if (!on_curve(base) || !on_curve(public_key)) return -1;
    if (multiply(base, n).infinity == false || multiply(public_key, n).infinity == false) return -1;
    if (output == NULL || capacity < 1) return -2;
    int64_t w = inverse(s, n);
    if (w == 0) return -1;
    int64_t u1 = digest * w % n;
    int64_t u2 = r * w % n;
    Point check = add(multiply(base, u1), multiply(public_key, u2));
    output[0] = (uint8_t)(!check.infinity && check.x % n == r);
    return 1;
}

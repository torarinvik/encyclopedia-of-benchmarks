#include <stddef.h>
#include <stdint.h>
int64_t polybius(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
    if (!v || n < 1 || n > 65 || v[0] < 0 || v[0] > 64 || n != (size_t)v[0] + 1) return -1;
    size_t count = (size_t)v[0], needed = count * 2;
    if (needed > cap || (needed && !out)) return -2;
    size_t k = 0;
    for (size_t i = 0; i < count; ++i) {
        int64_t x = v[i + 1]; if (x >= 'a' && x <= 'z') x -= 32;
        if (x < 'A' || x > 'Z' || x == 'J') return -1;
        int index = (int)(x - 'A'); if (x > 'J') --index;
        out[k++] = (uint8_t)('A' + index / 5); out[k++] = (uint8_t)('A' + index % 5);
    }
    return (int64_t)needed;
}

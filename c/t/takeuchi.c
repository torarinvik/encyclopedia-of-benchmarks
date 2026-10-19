#include <stdint.h>

#define MAX_INPUT 12

static int64_t tak(int64_t x, int64_t y, int64_t z) {
    if (y < x) {
        return tak(tak(x - 1, y, z), tak(y - 1, z, x), tak(z - 1, x, y));
    }
    return z;
}

int64_t takeuchi(int64_t x, int64_t y, int64_t z) {
    if (x < 0 || x > MAX_INPUT || y < 0 || y > MAX_INPUT || z < 0 || z > MAX_INPUT) return -1;
    return tak(x, y, z);
}

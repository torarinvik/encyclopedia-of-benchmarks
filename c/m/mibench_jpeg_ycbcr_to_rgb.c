#include <stddef.h>
#include <stdint.h>

#define MAX_PIXELS 16
#define MAX_INPUT 49
#define MAX_OUTPUT 48

static int64_t arshift16(int64_t x) {
    return x >= 0 ? x / 65536 : -((-x + 65535) / 65536);
}
static uint8_t clamp8(int64_t x) {
    return (uint8_t)(x < 0 ? 0 : (x > 255 ? 255 : x));
}

int64_t mibench_jpeg_ycbcr_to_rgb(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
    if (!v || n < 4 || n > MAX_INPUT) return -1;
    if (v[0] < 1 || v[0] > MAX_PIXELS || n != 1 + 3 * (size_t)v[0]) return -1;
    for (size_t i = 1; i < n; ++i) if (v[i] < 0 || v[i] > 255) return -1;
    uint8_t staged[MAX_OUTPUT];
    size_t p = 0;
    for (size_t i = 1; i < n; i += 3) {
        int64_t y = v[i], cb = v[i + 1] - 128, cr = v[i + 2] - 128;
        int64_t r = arshift16(91881 * cr + 32768);
        int64_t b = arshift16(116130 * cb + 32768);
        int64_t g = arshift16(-22554 * cb + 32768 - 46802 * cr);
        staged[p++] = clamp8(y + r); staged[p++] = clamp8(y + g); staged[p++] = clamp8(y + b);
    }
    size_t need = p;
    if (!out || cap < need) return -2;
    for (size_t i = 0; i < need; ++i) out[i] = staged[i];
    return (int64_t)need;
}

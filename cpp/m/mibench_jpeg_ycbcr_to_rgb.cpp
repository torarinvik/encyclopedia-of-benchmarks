#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
int64_t arshift16(int64_t x) { return x >= 0 ? x / 65536 : -((-x + 65535) / 65536); }
uint8_t clamp8(int64_t x) { return static_cast<uint8_t>(std::clamp<int64_t>(x, 0, 255)); }
}
extern "C" int64_t mibench_jpeg_ycbcr_to_rgb(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
    if (!v || n < 4 || n > 49) return -1;
    if (v[0] < 1 || v[0] > 16 || n != 1 + 3 * static_cast<size_t>(v[0])) return -1;
    for (size_t i = 1; i < n; ++i) if (v[i] < 0 || v[i] > 255) return -1;
    uint8_t staged[48]; size_t p = 0;
    for (size_t i = 1; i < n; i += 3) {
        const int64_t y=v[i], cb=v[i+1]-128, cr=v[i+2]-128;
        staged[p++]=clamp8(y+arshift16(91881*cr+32768));
        staged[p++]=clamp8(y+arshift16(-22554*cb+32768-46802*cr));
        staged[p++]=clamp8(y+arshift16(116130*cb+32768));
    }
    if (!out || cap < p) return -2;
    for (size_t i=0;i<p;++i) out[i]=staged[i];
    return static_cast<int64_t>(p);
}

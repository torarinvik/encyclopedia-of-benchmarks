#include <cstddef>
#include <cstdint>

namespace {
constexpr int kRange = 16;
constexpr int kDimension = 33;
constexpr int kPositions = 1089;
constexpr int kPad = 1092;
constexpr int kSlots = 41 * kPad;
constexpr int kTypeCount[8] = {0, 1, 2, 2, 4, 8, 8, 16};
constexpr int kTypeOffset[8] = {0, 0, 1, 3, 5, 9, 17, 25};

int pixel(const int64_t *values, int image, int y, int x) {
    const uint32_t packed = static_cast<uint32_t>(values[image * 64 + y * 4 + x / 4]);
    return static_cast<int>((packed >> ((x % 4) * 8)) & 255u);
}
}

extern "C" int64_t parboil_sad(const int64_t *values, size_t length) {
    if (values == nullptr || length != 128) return -1;
    for (size_t i = 0; i < length; ++i)
        if (values[i] < 0 || static_cast<uint64_t>(values[i]) > 4'294'967'295ULL) return -1;

    uint16_t sads[kSlots] = {};
    for (int py = -kRange; py <= kRange; ++py) {
        for (int px = -kRange; px <= kRange; ++px) {
            const int pos = (py + kRange) * kDimension + px + kRange;
            for (int by = 0; by < 4; ++by) {
                for (int bx = 0; bx < 4; ++bx) {
                    const int block = by * 4 + bx;
                    const int base = (kTypeOffset[7] + block) * kPad;
                    uint32_t sad = 0;
                    for (int y = 0; y < 4; ++y) {
                        for (int x = 0; x < 4; ++x) {
                            const int fy = by * 4 + y;
                            const int fx = bx * 4 + x;
                            const int ry = (fy + py < 0) ? 0 : ((fy + py > 15) ? 15 : fy + py);
                            const int rx = (fx + px < 0) ? 0 : ((fx + px > 15) ? 15 : fx + px);
                            const int delta = pixel(values, 0, fy, fx) - pixel(values, 1, ry, rx);
                            sad += static_cast<uint32_t>(delta < 0 ? -delta : delta);
                        }
                    }
                    sads[base + pos] = static_cast<uint16_t>(sad);
                }
            }
        }
    }

    for (int by = 0; by < 2; ++by) for (int bx = 0; bx < 4; ++bx) {
        const int dst = kTypeOffset[6] + 4 * by + bx, src = kTypeOffset[7] + 8 * by + bx;
        for (int p = 0; p < kPositions; ++p) sads[dst*kPad+p] = sads[src*kPad+p] + sads[(src+4)*kPad+p];
    }
    for (int by = 0; by < 4; ++by) for (int bx = 0; bx < 2; ++bx) {
        const int dst = kTypeOffset[5] + 2 * by + bx, src = kTypeOffset[7] + 4 * by + 2 * bx;
        for (int p = 0; p < kPositions; ++p) sads[dst*kPad+p] = sads[src*kPad+p] + sads[(src+1)*kPad+p];
    }
    for (int by = 0; by < 2; ++by) for (int bx = 0; bx < 2; ++bx) {
        const int dst = kTypeOffset[4] + 2 * by + bx, src = kTypeOffset[5] + 4 * by + bx;
        for (int p = 0; p < kPositions; ++p) sads[dst*kPad+p] = sads[src*kPad+p] + sads[(src+2)*kPad+p];
    }
    for (int bx = 0; bx < 2; ++bx) {
        const int dst = kTypeOffset[3] + bx, src = kTypeOffset[4] + bx;
        for (int p = 0; p < kPositions; ++p) sads[dst*kPad+p] = sads[src*kPad+p] + sads[(src+2)*kPad+p];
    }
    for (int by = 0; by < 2; ++by) {
        const int dst = kTypeOffset[2] + by, src = kTypeOffset[4] + 2 * by;
        for (int p = 0; p < kPositions; ++p) sads[dst*kPad+p] = sads[src*kPad+p] + sads[(src+1)*kPad+p];
    }
    for (int p = 0; p < kPositions; ++p)
        sads[kTypeOffset[1]*kPad+p] = sads[kTypeOffset[2]*kPad+p] + sads[(kTypeOffset[2]+1)*kPad+p];

    int64_t checksum = 0;
    for (int type = 1; type <= 7; ++type)
        for (int block = 0; block < kTypeCount[type]; ++block)
            for (int p = 0; p < kPositions; ++p) checksum += sads[(kTypeOffset[type]+block)*kPad+p];
    return checksum;
}

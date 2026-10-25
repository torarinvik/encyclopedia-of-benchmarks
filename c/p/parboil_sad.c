#include <stddef.h>
#include <stdint.h>

#define SAD_RANGE 16
#define SAD_DIM 33
#define SAD_POS 1089
#define SAD_PAD 1092
#define SAD_SLOTS (41 * SAD_PAD)

static const int type_count[8] = {0, 1, 2, 2, 4, 8, 8, 16};
static const int type_offset[8] = {0, 0, 1, 3, 5, 9, 17, 25};

static int pixel(const int64_t *values, int image, int y, int x) {
    size_t word_index = (size_t)image * 64 + (size_t)y * 4 + (size_t)(x / 4);
    uint32_t packed = (uint32_t)values[word_index];
    return (int)((packed >> ((x % 4) * 8)) & 255u);
}

int64_t parboil_sad(const int64_t *values, size_t length) {
    uint16_t sads[SAD_SLOTS] = {0};
    int yb, xb, py, px, y, x, pos;
    size_t i;

    if (values == NULL || length != 128) return -1;
    for (i = 0; i < length; ++i) {
        if (values[i] < 0 || (uint64_t)values[i] > UINT32_MAX) return -1;
    }

    /* Source sad4_cpu / sad4_one_macroblock, with one 16x16 macroblock. */
    for (py = -SAD_RANGE; py <= SAD_RANGE; ++py) {
        for (px = -SAD_RANGE; px <= SAD_RANGE; ++px) {
            pos = (py + SAD_RANGE) * SAD_DIM + px + SAD_RANGE;
            for (yb = 0; yb < 4; ++yb) {
                for (xb = 0; xb < 4; ++xb) {
                    int block = yb * 4 + xb;
                    size_t base = (size_t)(type_offset[7] + block) * SAD_PAD;
                    unsigned int sad = 0;
                    for (y = 0; y < 4; ++y) {
                        for (x = 0; x < 4; ++x) {
                            int fy = yb * 4 + y;
                            int fx = xb * 4 + x;
                            int ry = fy + py, rx = fx + px;
                            int delta;
                            if (ry < 0) ry = 0;
                            if (ry > 15) ry = 15;
                            if (rx < 0) rx = 0;
                            if (rx > 15) rx = 15;
                            delta = pixel(values, 0, fy, fx) - pixel(values, 1, ry, rx);
                            sad += (unsigned int)(delta < 0 ? -delta : delta);
                        }
                    }
                    sads[base + (size_t)pos] = (uint16_t)sad;
                }
            }
        }
    }

    /* Source larger_sads hierarchy: types 6, 5, 4, 3, 2, then 1. */
    for (yb = 0; yb < 2; ++yb) for (xb = 0; xb < 4; ++xb) {
        int dst = type_offset[6] + 4 * yb + xb;
        int src = type_offset[7] + 8 * yb + xb;
        for (pos = 0; pos < SAD_POS; ++pos)
            sads[dst * SAD_PAD + pos] = (uint16_t)(sads[src * SAD_PAD + pos] + sads[(src + 4) * SAD_PAD + pos]);
    }
    for (yb = 0; yb < 4; ++yb) for (xb = 0; xb < 2; ++xb) {
        int dst = type_offset[5] + 2 * yb + xb;
        int src = type_offset[7] + 4 * yb + 2 * xb;
        for (pos = 0; pos < SAD_POS; ++pos)
            sads[dst * SAD_PAD + pos] = (uint16_t)(sads[src * SAD_PAD + pos] + sads[(src + 1) * SAD_PAD + pos]);
    }
    for (yb = 0; yb < 2; ++yb) for (xb = 0; xb < 2; ++xb) {
        int dst = type_offset[4] + 2 * yb + xb;
        int src = type_offset[5] + 4 * yb + xb;
        for (pos = 0; pos < SAD_POS; ++pos)
            sads[dst * SAD_PAD + pos] = (uint16_t)(sads[src * SAD_PAD + pos] + sads[(src + 2) * SAD_PAD + pos]);
    }
    for (xb = 0; xb < 2; ++xb) {
        int dst = type_offset[3] + xb;
        int src = type_offset[4] + xb;
        for (pos = 0; pos < SAD_POS; ++pos)
            sads[dst * SAD_PAD + pos] = (uint16_t)(sads[src * SAD_PAD + pos] + sads[(src + 2) * SAD_PAD + pos]);
    }
    for (yb = 0; yb < 2; ++yb) {
        int dst = type_offset[2] + yb;
        int src = type_offset[4] + 2 * yb;
        for (pos = 0; pos < SAD_POS; ++pos)
            sads[dst * SAD_PAD + pos] = (uint16_t)(sads[src * SAD_PAD + pos] + sads[(src + 1) * SAD_PAD + pos]);
    }
    for (pos = 0; pos < SAD_POS; ++pos)
        sads[type_offset[1] * SAD_PAD + pos] = (uint16_t)(sads[type_offset[2] * SAD_PAD + pos] + sads[(type_offset[2] + 1) * SAD_PAD + pos]);

    {
        int type, block;
        int64_t checksum = 0;
        for (type = 1; type <= 7; ++type)
            for (block = 0; block < type_count[type]; ++block)
                for (pos = 0; pos < SAD_POS; ++pos)
                    checksum += sads[(type_offset[type] + block) * SAD_PAD + pos];
        return checksum;
    }
}

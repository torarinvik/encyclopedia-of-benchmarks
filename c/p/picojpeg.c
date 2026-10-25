#include <stddef.h>
#include <stdint.h>

#define INPUT_BYTES 139
#define OUTPUT_BYTES 64

static int64_t floor_div_q16(int64_t value) {
    if (value >= 0) return value / 65536;
    return -((-value + 65535) / 65536);
}

static int valid_jpeg_block(const int64_t *v) {
    if (v[0] != 255 || v[1] != 216 || v[2] != 255 || v[3] != 219
            || v[4] != 0 || v[5] != 67 || v[6] != 0) return 0;
    for (size_t i = 0; i < 64; ++i) {
        if (v[7 + i] < 1 || v[7 + i] > 255 || (i >= 2 && v[7 + i] != 1)) return 0;
    }
    const uint8_t sof[] = {255,192,0,11,8,0,8,0,8,1,1,17,0};
    for (size_t i = 0; i < sizeof sof; ++i) if (v[71 + i] != sof[i]) return 0;
    if (v[84] != 255 || v[85] != 196 || v[86] != 0 || v[87] != 39 || v[88] != 0
            || v[89] != 1 || v[90] != 0 || v[105] != 4 || v[106] != 16
            || v[107] != 1 || v[108] != 1 || v[123] != 4 || v[124] != 0) return 0;
    for (size_t i = 91; i < 105; ++i) if (v[i] != 0) return 0;
    for (size_t i = 109; i < 123; ++i) if (v[i] != 0) return 0;
    const uint8_t sos[] = {255,218,0,8,1,1,0,0,63,0};
    for (size_t i = 0; i < sizeof sos; ++i) if (v[125 + i] != sos[i]) return 0;
    return v[137] == 255 && v[138] == 217;
}

int64_t picojpeg(const int64_t *v, size_t length, uint8_t *out, size_t capacity) {
    if (!v || length != INPUT_BYTES) return -1;
    for (size_t i = 0; i < length; ++i) if (v[i] < 0 || v[i] > 255) return -1;
    if (!valid_jpeg_block(v)) return -1;
    uint16_t scan = (uint16_t)((v[135] << 8) | v[136]);
    if ((scan & 0x8000) || (scan & 0x0400) || ((scan >> 4) & 3) != 2
            || (scan & 15) != 15) return -1;
    int dc_raw = (scan >> 11) & 15;
    int ac_raw = (scan >> 6) & 15;
    int dc = dc_raw >= 8 ? dc_raw : dc_raw - 15;
    int ac = ac_raw >= 8 ? ac_raw : ac_raw - 15;
    int64_t dequant_dc = (int64_t)dc * v[7];
    int64_t dequant_ac = (int64_t)ac * v[8];
    if (!out || capacity < OUTPUT_BYTES) return -2;
    static const int factors[8] = {11363,9633,6436,2260,-2260,-6436,-9633,-11363};
    for (size_t y = 0; y < 8; ++y) {
        for (size_t x = 0; x < 8; ++x) {
            int64_t numerator = 128 * INT64_C(65536) + dequant_dc * 8192
                              + dequant_ac * factors[x] + 32768;
            int64_t pixel = floor_div_q16(numerator);
            if (pixel < 0) pixel = 0;
            if (pixel > 255) pixel = 255;
            out[y * 8 + x] = (uint8_t)pixel;
        }
    }
    return OUTPUT_BYTES;
}

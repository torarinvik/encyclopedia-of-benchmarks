module parboil_sad;

const int SAD_RANGE = 16;
const int SAD_DIM = 33;
const int SAD_POS = 1089;
const int SAD_PAD = 1092;
const int SAD_SLOTS = 44772;
const int[8] TYPE_COUNT = {0, 1, 2, 2, 4, 8, 8, 16};
const int[8] TYPE_OFFSET = {0, 0, 1, 3, 5, 9, 17, 25};

fn int pixel(long* values, int image, int y, int x) {
    uint packed = (uint)values[image * 64 + y * 4 + x / 4];
    return (int)((packed >> ((x % 4) * 8)) & 255);
}

fn long parboil_sad(long* values, usz length) @export("parboil_sad") {
    if (values == null || length != 128) return -1;
    for (usz i = 0; i < length; i++)
        if (values[i] < 0 || values[i] > 4294967295L) return -1;

    ushort[SAD_SLOTS] sads = {};
    for (int py = -SAD_RANGE; py <= SAD_RANGE; py++) {
        for (int px = -SAD_RANGE; px <= SAD_RANGE; px++) {
            int pos = (py + SAD_RANGE) * SAD_DIM + px + SAD_RANGE;
            for (int by = 0; by < 4; by++) {
                for (int bx = 0; bx < 4; bx++) {
                    int block = by * 4 + bx;
                    int base = (TYPE_OFFSET[7] + block) * SAD_PAD;
                    uint sad = 0;
                    for (int y = 0; y < 4; y++) for (int x = 0; x < 4; x++) {
                        int fy = by * 4 + y, fx = bx * 4 + x;
                        int ry = fy + py, rx = fx + px;
                        if (ry < 0) ry = 0; if (ry > 15) ry = 15;
                        if (rx < 0) rx = 0; if (rx > 15) rx = 15;
                        int delta = pixel(values, 0, fy, fx) - pixel(values, 1, ry, rx);
                        sad += (uint)(delta < 0 ? -delta : delta);
                    }
                    sads[base + pos] = (ushort)sad;
                }
            }
        }
    }

    for (int by = 0; by < 2; by++) for (int bx = 0; bx < 4; bx++) {
        int dst = TYPE_OFFSET[6] + 4 * by + bx, src = TYPE_OFFSET[7] + 8 * by + bx;
        for (int p = 0; p < SAD_POS; p++) sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+4)*SAD_PAD+p];
    }
    for (int by = 0; by < 4; by++) for (int bx = 0; bx < 2; bx++) {
        int dst = TYPE_OFFSET[5] + 2 * by + bx, src = TYPE_OFFSET[7] + 4 * by + 2 * bx;
        for (int p = 0; p < SAD_POS; p++) sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+1)*SAD_PAD+p];
    }
    for (int by = 0; by < 2; by++) for (int bx = 0; bx < 2; bx++) {
        int dst = TYPE_OFFSET[4] + 2 * by + bx, src = TYPE_OFFSET[5] + 4 * by + bx;
        for (int p = 0; p < SAD_POS; p++) sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+2)*SAD_PAD+p];
    }
    for (int bx = 0; bx < 2; bx++) {
        int dst = TYPE_OFFSET[3] + bx, src = TYPE_OFFSET[4] + bx;
        for (int p = 0; p < SAD_POS; p++) sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+2)*SAD_PAD+p];
    }
    for (int by = 0; by < 2; by++) {
        int dst = TYPE_OFFSET[2] + by, src = TYPE_OFFSET[4] + 2 * by;
        for (int p = 0; p < SAD_POS; p++) sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+1)*SAD_PAD+p];
    }
    for (int p = 0; p < SAD_POS; p++) sads[TYPE_OFFSET[1]*SAD_PAD+p] = sads[TYPE_OFFSET[2]*SAD_PAD+p] + sads[(TYPE_OFFSET[2]+1)*SAD_PAD+p];

    long checksum = 0;
    for (int type = 1; type <= 7; type++)
        for (int block = 0; block < TYPE_COUNT[type]; block++)
            for (int p = 0; p < SAD_POS; p++) checksum += sads[(TYPE_OFFSET[type]+block)*SAD_PAD+p];
    return checksum;
}

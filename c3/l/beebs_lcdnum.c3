module beebs_lcdnum;

const usz INPUT_BYTES = 5;
const uchar[16] SEGMENT_MASKS = {0x00,0x24,0x5D,0x6D,0x2E,0x5D,0x7B,0x25,0x7F,0x6F,0x3F,0x7A,0x53,0x7C,0x5B,0x1B};

fn long beebs_lcdnum(long* values, usz length, uchar* output, usz capacity)
    @export("beebs_lcdnum") {
    if (values == null || length != INPUT_BYTES) return -1;
    for (usz i = 0; i < INPUT_BYTES; i++)
        if (values[i] < 0 || values[i] > 255) return -1;
    if (output == null || capacity < INPUT_BYTES) return -2;
    for (usz i = 0; i < INPUT_BYTES; i++)
        output[i] = SEGMENT_MASKS[(uchar)values[i] & 0x0F];
    return (long)INPUT_BYTES;
}

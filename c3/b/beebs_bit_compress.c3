module beebs_bit_compress;

fn long beebs_bit_compress(long* values, usz length) @export("beebs_bit_compress") {
    if (values == null || length != 2) return -1;
    if (values[0] < 0 || values[0] > 4294967295 ||
        values[1] < 0 || values[1] > 4294967295) return -1;

    uint data = (uint)values[0];
    uint mask = (uint)values[1];
    uint packed = 0;
    uint output_bit = 1;
    while (mask != 0) {
        if ((mask & 1) != 0) {
            if ((data & 1) != 0) packed |= output_bit;
            output_bit <<= 1;
        }
        data >>= 1;
        mask >>= 1;
    }
    return (long)packed;
}

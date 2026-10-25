module mibench_automotive_basicmath_isqrt;

fn long mibench_automotive_basicmath_isqrt(long* input, usz length) @export("mibench_automotive_basicmath_isqrt") {
    if (input == null || length != 1) return -1;
    if (input[0] < 0 || input[0] > 65535) return -1;
    uint x = (uint)input[0];
    uint root = 0, remainder = 0;
    for (int step = 0; step < 32; step++) {
        remainder = (remainder << 2) + (x >> 30);
        x <<= 2;
        root <<= 1;
        uint trial = (root << 1) + 1;
        if (remainder >= trial) {
            remainder -= trial;
            root += 1;
        }
    }
    return (long)root;
}

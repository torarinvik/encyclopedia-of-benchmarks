module fletcher16;

const usz MAX_BYTES = 4096;

fn long fletcher16(long* input, usz length) @export("fletcher16") {
    if (length > MAX_BYTES || (length != 0 && input == null)) return -1;
    uint sum1 = 0;
    uint sum2 = 0;
    for (usz index = 0; index < length; index++) {
        long byte = input[index];
        if (byte < 0 || byte > 127) return -1;
        sum1 = (sum1 + (uint)byte) % 255u;
        sum2 = (sum2 + sum1) % 255u;
    }
    return (long)((sum2 << 8) | sum1);
}

module alaw;

fn long alaw_encode(long input) @export("alaw_encode") {
    if (input < -32768 || input > 32767) return -1;
    int sample = (int)input;
    int sign = sample < 0 ? 0x80 : 0;
    int magnitude = sample < 0 ? -sample - 1 : sample;
    int segment = 7;
    int mask = 0x4000;
    while ((magnitude & mask) == 0 && segment > 0) {
        segment--;
        mask >>= 1;
    }
    int shift = segment != 0 ? segment + 3 : 4;
    int quantization = (magnitude >> shift) & 0x0f;
    return (sign | (segment << 4) | quantization) ^ 0xD5;
}

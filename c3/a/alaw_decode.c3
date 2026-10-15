module alaw_decode;

fn long alaw_decode(long input) @export("alaw_decode") {
    if (input < 0 || input > 255) return -1;
    int alaw = (int)input ^ 0xD5;
    int sign = alaw & 0x80;
    int segment = (alaw & 0x70) >> 4;
    int sample = ((alaw & 0x0F) << 4) | 8;
    if (segment != 0) sample += 0x100;
    int shift = segment > 1 ? segment - 1 : 0;
    sample <<= shift;
    return sign != 0 ? -(long)sample : (long)sample;
}

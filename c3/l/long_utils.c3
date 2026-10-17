module long_utils;

fn long long_utils(long* input, usz length, char* output, usz capacity)
    @export("long_utils") {
    if (input == null || length != 3) return -1;
    if (input[0] < 0 || input[0] > 3 || input[2] < 0 || input[2] > 63) return -1;
    if (output == null || capacity < 8) return -2;
    ulong bits = (ulong)input[1];
    usz distance = (usz)input[2];
    ulong rotated = bits;
    if (distance != 0) {
        if (input[0] < 2) rotated = (bits << distance) | (bits >> (64 - distance));
        else rotated = (bits >> distance) | (bits << (64 - distance));
    }
    for (usz byte = 0; byte < 8; byte++)
        output[byte] = (char)((rotated >> (8 * byte)) & 255);
    8
}

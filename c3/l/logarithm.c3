module logarithm;

fn long logarithm(long input) @export("logarithm") {
    if (input < 1 || input > 4_294_967_295) return -1;
    long value = input;
    long result = 0;
    if ((value & 0xFFFF0000) != 0) { value >>= 16; result += 16; }
    if ((value & 0x0000FF00) != 0) { value >>= 8; result += 8; }
    if ((value & 0x000000F0) != 0) { value >>= 4; result += 4; }
    if ((value & 0x0000000C) != 0) { value >>= 2; result += 2; }
    if ((value & 0x00000002) != 0) result += 1;
    return result;
}

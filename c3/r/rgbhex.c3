module rgbhex;

fn long rgbhex(long* input, usz length) @export("rgbhex") {
    if (input == null || length != 4) return -1;
    long op = input[0];
    long x = input[1];
    long y = input[2];
    long z = input[3];
    if (op == 0) {
        if (x < 0 || x > 4294967295L || y != 0 || z != 0) return -1;
        return x & 0x00ffffffL;
    }
    if (op == 1) {
        if (x < 0 || x > 255 || y < 0 || y > 255 || z < 0 || z > 255) return -1;
        return (x << 16) | (y << 8) | z;
    }
    return -1;
}

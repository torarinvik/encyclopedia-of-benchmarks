export fn rgbhex(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 4) return -1;
    const op = input[0];
    const x = input[1];
    const y = input[2];
    const z = input[3];
    if (op == 0) {
        if (x < 0 or x > 4294967295 or y != 0 or z != 0) return -1;
        return x & 0x00ffffff;
    }
    if (op == 1) {
        if (x < 0 or x > 255 or y < 0 or y > 255 or z < 0 or z > 255) return -1;
        return (x << 16) | (y << 8) | z;
    }
    return -1;
}

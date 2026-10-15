module xs3_conversion;

fn long xs3_conversion(long* packed, usz length) @export("xs3_conversion")
{
    if (length != 2) return -1;
    long direction = packed[0];
    long value = packed[1];
    if (direction == 0) {
        if (value < 0 || value > 2147483647) return -1;
        long decoded = 0;
        long multiplier = 1;
        while (value > 0) {
            long nibble = value & 15;
            if (nibble < 3 || nibble > 12) return -1;
            decoded += (nibble - 3) * multiplier;
            multiplier *= 10;
            value >>= 4;
        }
        return decoded;
    }
    if (direction == 1) {
        if (value < 0 || value > 9999999) return -1;
        long encoded = 0;
        usz shift = 0;
        while (value > 0) {
            long digit = value % 10 + 3;
            encoded |= digit << (shift * 4);
            value /= 10;
            shift++;
        }
        return encoded;
    }
    return -1;
}

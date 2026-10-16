module endianness;

fn long signed_u64(ulong bits) {
    if (bits <= 0x7FFFFFFFFFFFFFFF) return (long)bits;
    return -1L - (long)(0xFFFFFFFFFFFFFFFF - bits);
}

fn ulong swap_bytes(ulong bits, usz count) {
    ulong reversed = 0;
    for (usz i = 0; i < count; i++) {
        reversed = (reversed << 8) | (bits & 0xFF);
        bits >>= 8;
    }
    return reversed;
}

fn long endianness(long* input, usz length) @export("endianness") {
    if (input == null || length == 0) return -1;
    long operation = input[0];
    if (operation >= 0 && operation <= 2) {
        if (length != 2) return -1;
        long value = input[1];
        if (operation == 0) {
            if (value < 0 || value > 65535) return -1;
            return (long)swap_bytes((ulong)value, 2);
        }
        if (operation == 1) {
            if (value < 0 || (ulong)value > 0xFFFFFFFF) return -1;
            return (long)swap_bytes((ulong)value, 4);
        }
        return signed_u64(swap_bytes((ulong)value, 8));
    }
    if (operation == 3 || operation == 4) {
        if (length < 3 || input[1] < 1 || input[1] > 8 || length != (usz)input[1] + 2) return -1;
        ulong result = 0;
        usz count = (usz)input[1];
        for (usz i = 0; i < count; i++) {
            long byte = input[i + 2];
            if (byte < 0 || byte > 255) return -1;
            usz shift = operation == 3 ? 8 * i : 8 * (count - 1 - i);
            result |= (ulong)byte << shift;
        }
        return signed_u64(result);
    }
    if (operation == 5 || operation == 6) {
        if (length != 3 || input[2] < 1 || input[2] > 8) return -1;
        usz count = (usz)input[2];
        ulong value = (ulong)input[1];
        if (count < 8 && (input[1] < 0 || (value >> (8 * count)) != 0)) return -1;
        return signed_u64(operation == 5 ? value : swap_bytes(value, count));
    }
    return -1;
}

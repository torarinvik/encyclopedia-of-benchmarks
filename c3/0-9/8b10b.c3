module versabench_8b10b;

const uint[32] RAW5 = {
    0x0d80, 0x05a2, 0x0c60, 0x0cc0, 0x0ca0, 0x10a2, 0x10c2, 0x10e0,
    0x0d20, 0x1122, 0x1142, 0x1160, 0x1182, 0x11a0, 0x11c0, 0x05e0,
    0x0e20, 0x1222, 0x1242, 0x1260, 0x1282, 0x12a0, 0x12c0, 0x06e0,
    0x1302, 0x1320, 0x1340, 0x0760, 0x0380, 0x07a0, 0x0e80, 0x06a2
};
const uint[8] RAW3 = {0x0c08, 0x0c04, 0x1009, 0x100c, 0x1011, 0x1014, 0x0018, 0x041c};

fn uint encode_one(uint packed_word, uint* disparity) {
    uint data = packed_word & 0xff;
    uint k = packed_word >> 8;
    uint index5 = data >> 3;
    uint index3 = data & 7;
    uint lookup5 = RAW5[index5.usz()];
    uint lookup3 = RAW3[index3.usz()];
    if (k == 1 && index5 == 7) lookup5 = 0x04e2;
    if (k == 1) {
        if (index3 >= 2 && index3 <= 5) lookup3 = (lookup3 & ~0x1000) | 0x0800;
        else if (index3 == 7) lookup3 = 0x040d;
    }

    uint result;
    uint disparity1;
    if ((lookup5 & 0x1000) != 0) {
        result = lookup5 & 0x03e2;
        disparity1 = *disparity;
    } else {
        uint code5 = lookup5 & 0x03e2;
        uint plus5 = 0;
        if ((lookup5 & 0x0800) != 0) plus5 = 1;
        result = *disparity == plus5 ? code5 : code5 ^ 0x03e2;
        uint flip5 = 0;
        if ((lookup5 & 0x0400) != 0) flip5 = 1;
        disparity1 = *disparity ^ flip5;
    }

    if ((lookup3 & 0x1000) != 0) {
        result |= lookup3 & 0x001d;
        *disparity = disparity1;
    } else {
        uint code3 = lookup3 & 0x001d;
        uint plus3 = 0;
        if ((lookup3 & 0x0800) != 0) plus3 = 1;
        result |= disparity1 == plus3 ? code3 : code3 ^ 0x001d;
        uint flip3 = 0;
        if ((lookup3 & 0x0400) != 0) flip3 = 1;
        *disparity = disparity1 ^ flip3;
    }
    return result;
}

fn usz append_line(uint value, char* staged, usz used) {
    for (usz digit = 0; digit < 8; digit++) {
        uint shift = ((7 - digit) * 4).uint();
        uint nibble = (value >> shift) & 15;
        staged[used++] = nibble < 10 ? (char)(48 + nibble) : (char)(55 + nibble);
    }
    staged[used++] = '\n';
    return used;
}

fn long versabench_8b10b(long* values, usz length, char* output, usz output_capacity)
    @export("versabench_8b10b") {
    if (length > 160 || (length != 0 && values == null)) return -1;
    for (usz index = 0; index < length; index++)
        if (values[index] < 0 || values[index] > 511) return -1;

    usz sample_count = length == 0 ? 0 : 1 + (length - 1) / 128;
    usz required = sample_count * 9;
    if (required != 0 && (output == null || output_capacity < required)) return -2;

    char[18] staged;
    usz used = 0;
    uint disparity = 0;
    for (usz pass_index = 0; pass_index < length; pass_index++) {
        for (usz index = 0; index < length; index++) {
            uint encoded = encode_one(values[index].uint(), &disparity);
            if (pass_index + 1 == length && index % 128 == 0) used = append_line(encoded, &staged, used);
        }
    }
    for (usz index = 0; index < required; index++) output[index] = staged[index];
    return used.long();
}

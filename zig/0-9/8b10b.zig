const MAX_WORDS: usize = 160;
const MAX_OUTPUT_BYTES: usize = 18;
const RAW5: [32]u16 = .{
    0x0d80, 0x05a2, 0x0c60, 0x0cc0, 0x0ca0, 0x10a2, 0x10c2, 0x10e0,
    0x0d20, 0x1122, 0x1142, 0x1160, 0x1182, 0x11a0, 0x11c0, 0x05e0,
    0x0e20, 0x1222, 0x1242, 0x1260, 0x1282, 0x12a0, 0x12c0, 0x06e0,
    0x1302, 0x1320, 0x1340, 0x0760, 0x0380, 0x07a0, 0x0e80, 0x06a2,
};
const RAW3: [8]u16 = .{ 0x0c08, 0x0c04, 0x1009, 0x100c, 0x1011, 0x1014, 0x0018, 0x041c };

fn encodeOne(packed_word: u32, disparity: *u32) u32 {
    const data = packed_word & 0xff;
    const k = packed_word >> 8;
    const index5: usize = @intCast(data >> 3);
    const index3: usize = @intCast(data & 7);
    var lookup5: u32 = RAW5[index5];
    var lookup3: u32 = RAW3[index3];
    if (k == 1 and index5 == 7) lookup5 = 0x04e2;
    if (k == 1) {
        if (index3 >= 2 and index3 <= 5) {
            lookup3 = (lookup3 & ~@as(u32, 0x1000)) | 0x0800;
        } else if (index3 == 7) {
            lookup3 = 0x040d;
        }
    }

    var result: u32 = undefined;
    var disparity1: u32 = undefined;
    if ((lookup5 & 0x1000) != 0) {
        result = lookup5 & 0x03e2;
        disparity1 = disparity.*;
    } else {
        const code5 = lookup5 & 0x03e2;
        const plus5: u32 = if ((lookup5 & 0x0800) != 0) 1 else 0;
        const flip5: u32 = if ((lookup5 & 0x0400) != 0) 1 else 0;
        result = if (disparity.* == plus5) code5 else code5 ^ 0x03e2;
        disparity1 = disparity.* ^ flip5;
    }

    if ((lookup3 & 0x1000) != 0) {
        result |= lookup3 & 0x001d;
        disparity.* = disparity1;
    } else {
        const code3 = lookup3 & 0x001d;
        const plus3: u32 = if ((lookup3 & 0x0800) != 0) 1 else 0;
        const flip3: u32 = if ((lookup3 & 0x0400) != 0) 1 else 0;
        result |= if (disparity1 == plus3) code3 else code3 ^ 0x001d;
        disparity.* = disparity1 ^ flip3;
    }
    return result;
}

fn appendLine(value: u32, staged: *[MAX_OUTPUT_BYTES]u8, used: *usize) void {
    const hex = "0123456789ABCDEF";
    for (0..8) |digit| {
        const shift: u5 = @intCast((7 - digit) * 4);
        staged[used.*] = hex[@as(usize, @intCast((value >> shift) & 15))];
        used.* += 1;
    }
    staged[used.*] = '\n';
    used.* += 1;
}

export fn versabench_8b10b(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (length > MAX_WORDS or (length != 0 and values == null)) return -1;
    for (0..length) |index| if (values[index] < 0 or values[index] > 511) return -1;

    const sample_count = if (length == 0) 0 else 1 + (length - 1) / 128;
    const required = sample_count * 9;
    if (required != 0 and (output == null or output_capacity < required)) return -2;

    var staged = [_]u8{0} ** MAX_OUTPUT_BYTES;
    var used: usize = 0;
    var disparity: u32 = 0;
    for (0..length) |pass_index| {
        for (0..length) |index| {
            const encoded = encodeOne(@intCast(values[index]), &disparity);
            if (pass_index + 1 == length and index % 128 == 0)
                appendLine(encoded, &staged, &used);
        }
    }
    if (required != 0) @memcpy(output[0..required], staged[0..required]);
    return @intCast(used);
}

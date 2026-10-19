// ARC4 port from Trimaran/enc-rc4, Copyright (C) 2001-2003 Christophe Devine.
// Distributed under GPL-2.0-or-later; see the package license notice.
const OUTPUT_BYTES: usize = 82;
const MAX_PASSES: i64 = 2000;
const key_lengths = [_]usize{ 8, 8, 8, 4, 8, 4 };
const data_lengths = [_]usize{ 8, 8, 8, 20, 28, 10 };
const output_offsets = [_]usize{ 0, 8, 16, 24, 44, 72 };

fn cryptOne(keys: []const u8, keyBase: usize, keyLength: usize,
            staged: []u8, dataBase: usize, dataLength: usize) void {
    var state: [256]i32 = undefined;
    for (0..256) |index| state[index] = @intCast(index);
    var j: usize = 0;
    for (0..256) |index| {
        j = (j + @as(usize, @intCast(state[index])) + keys[keyBase + index % keyLength]) & 255;
        const temp = state[index]; state[index] = state[j]; state[j] = temp;
    }
    var x: usize = 0;
    var y: usize = 0;
    for (0..dataLength) |offset| {
        x = (x + 1) & 255;
        const a: usize = @intCast(state[x]);
        y = (y + a) & 255;
        const b: usize = @intCast(state[y]);
        state[x] = @intCast(b); state[y] = @intCast(a);
        staged[dataBase + offset] ^= @intCast(state[(a + b) & 255]);
    }
}

export fn trimaran_enc_rc4(input: ?[*]const i64, length: usize,
                           output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length != 1) return -1;
    const passes_value = input.?[0];
    if (passes_value < 1 or passes_value > MAX_PASSES) return -1;
    if (output == null or output_capacity < OUTPUT_BYTES) return -2;

    var keys = [_]u8{0} ** 48;
    const key_a = [_]u8{ 0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef };
    const key_b = [_]u8{ 0xef,0x01,0x23,0x45 };
    @memcpy(keys[0..8], &key_a);
    @memcpy(keys[8..16], &key_a);
    @memcpy(keys[24..28], &key_b);
    @memcpy(keys[32..40], &key_a);
    @memcpy(keys[40..44], &key_b);
    var plaintexts = [_]u8{0} ** 168;
    const data_a = [_]u8{ 0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef };
    const data_b = [_]u8{ 0x12,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,
        0x12,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,
        0x12,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,0x12,0x34,0x56,0x78 };
    @memcpy(plaintexts[0..8], &data_a);
    @memcpy(plaintexts[112..140], &data_b);
    var staged = [_]u8{0} ** OUTPUT_BYTES;
    for (0..6) |vector| {
        const output_base = output_offsets[vector];
        const input_base = vector * 28;
        for (0..@intCast(passes_value)) |_| {
            @memcpy(staged[output_base .. output_base + data_lengths[vector]],
                    plaintexts[input_base .. input_base + data_lengths[vector]]);
            cryptOne(keys[0..], vector * 8, key_lengths[vector], staged[0..], output_base, data_lengths[vector]);
        }
    }
    for (0..OUTPUT_BYTES) |index| output.?[index] = staged[index];
    return OUTPUT_BYTES;
}

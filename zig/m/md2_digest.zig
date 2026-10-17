const std = @import("std");

const MD2_S: [256]u8 = .{
    41,46,67,201,162,216,124,1,61,54,84,161,236,240,6,19,98,167,5,243,192,199,115,140,152,147,43,217,188,76,130,202,
    30,155,87,60,253,212,224,22,103,66,111,24,138,23,229,18,190,78,196,214,218,158,222,73,160,251,245,142,187,47,238,122,
    169,104,121,145,21,178,7,63,148,194,16,137,11,34,95,33,128,127,93,154,90,144,50,39,53,62,204,231,191,247,151,3,
    255,25,48,179,72,165,181,209,215,94,146,42,172,86,170,198,79,184,56,210,150,164,125,182,118,252,107,226,156,116,4,241,
    69,157,112,89,100,113,135,32,134,91,207,101,230,45,168,2,27,96,37,173,174,176,185,246,28,70,97,105,52,64,126,15,
    85,71,163,35,221,81,175,58,195,92,249,206,186,197,234,38,44,83,13,110,133,40,132,9,211,223,205,244,65,129,77,82,
    106,220,55,200,108,193,171,250,36,225,123,8,12,189,177,74,120,136,149,139,227,99,232,109,233,203,213,254,59,0,29,57,
    242,239,183,14,102,88,208,228,166,119,114,248,235,117,75,10,49,68,80,180,143,237,31,26,219,153,141,51,159,17,131,20,
};

export fn md2_digest(input: [*c]const f64, length: usize, output: [*c]f64, capacity: usize) i64 {
    if (length > 63 or (length != 0 and input == null)) return -1;
    var bytes: [64]u8 = undefined;
    for (0..length) |index| {
        const value = input[index];
        if (!std.math.isFinite(value) or value < 0.0 or value > 255.0 or @floor(value) != value) return -1;
        bytes[index] = @intFromFloat(value);
    }
    if (output == null or capacity < 16) return -2;

    const padding_length = 16 - length % 16;
    const padded_length = length + padding_length;
    for (length..padded_length) |index| bytes[index] = @intCast(padding_length);
    var checksum = [_]u8{0} ** 16;
    var last: u8 = 0;
    var offset: usize = 0;
    while (offset < padded_length) : (offset += 16) {
        for (0..16) |index| {
            checksum[index] ^= MD2_S[@as(usize, bytes[offset + index] ^ last)];
            last = checksum[index];
        }
    }

    var state = [_]u8{0} ** 48;
    offset = 0;
    while (offset <= padded_length) : (offset += 16) {
        for (0..16) |index| {
            const byte = if (offset < padded_length) bytes[offset + index] else checksum[index];
            state[index + 16] = byte;
            state[index + 32] = state[index] ^ byte;
        }
        var temporary: u8 = 0;
        for (0..18) |round| {
            for (0..48) |index| {
                state[index] ^= MD2_S[@as(usize, temporary)];
                temporary = state[index];
            }
            temporary +%= @intCast(round);
        }
    }
    for (0..16) |index| output[index] = @floatFromInt(state[index]);
    return 16;
}

// Copyright (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
export fn prolangs_c_loader_relocation_add(input: [*]const i64, length: usize,
    output: [*]u8, capacity: usize) i64 {
    if (length < 3 or length > 5) return -1;
    const half_bytes = input[0];
    const delta = input[1];
    if (half_bytes < 1 or half_bytes > 6 or delta < -65535 or delta > 65535) return -1;
    const width: usize = @intCast(@divTrunc(half_bytes + 1, 2));
    if (length != 2 + width) return -1;
    var field: u32 = 0;
    for (0..width) |i| {
        const byte = input[2 + i];
        if (byte < 0 or byte > 255) return -1;
        field = field * 256 + @as(u32, @intCast(byte));
    }
    const adjusted: i64 = @as(i64, field) + delta;
    if (adjusted < 0) return -1;
    if (capacity < width) return -2;
    var result: u32 = @intCast(adjusted);
    var i = width;
    while (i > 0) {
        i -= 1;
        output[i] = @truncate(result & 255);
        result >>= 8;
    }
    return @intCast(width);
}

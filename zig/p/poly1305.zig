const MAX_MESSAGE_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 98;
const LIMB_MASK: u64 = 0x3ff_ffff;

fn load32Le(bytes: []const u8, offset: usize) u64 {
    return @as(u64, bytes[offset]) | (@as(u64, bytes[offset + 1]) << 8) |
        (@as(u64, bytes[offset + 2]) << 16) | (@as(u64, bytes[offset + 3]) << 24);
}

fn store32Le(output: []u8, offset: usize, value: u32) void {
    for (0..4) |byte| output[offset + byte] = @truncate(value >> @intCast(8 * byte));
}

fn poly1305Tag(key: []const u8, message: []const u8, message_length: usize, tag: []u8) void {
    const r0 = load32Le(key, 0) & 0x3ff_ffff;
    const r1 = (load32Le(key, 3) >> 2) & 0x3ff_ff03;
    const r2 = (load32Le(key, 6) >> 4) & 0x3ff_c0ff;
    const r3 = (load32Le(key, 9) >> 6) & 0x3f0_3fff;
    const r4 = (load32Le(key, 12) >> 8) & 0x00f_ffff;
    const s1 = r1 * 5; const s2 = r2 * 5; const s3 = r3 * 5; const s4 = r4 * 5;
    var h0: u64 = 0; var h1: u64 = 0; var h2: u64 = 0; var h3: u64 = 0; var h4: u64 = 0;
    var offset: usize = 0;
    while (offset < message_length) {
        var block = [_]u8{0} ** 16;
        const block_length = @min(16, message_length - offset);
        @memcpy(block[0..block_length], message[offset .. offset + block_length]);
        var high_bit: u64 = 1 << 24;
        if (block_length < 16) { block[block_length] = 1; high_bit = 0; }
        h0 += load32Le(block[0..], 0) & LIMB_MASK;
        h1 += (load32Le(block[0..], 3) >> 2) & LIMB_MASK;
        h2 += (load32Le(block[0..], 6) >> 4) & LIMB_MASK;
        h3 += (load32Le(block[0..], 9) >> 6) & LIMB_MASK;
        h4 += (load32Le(block[0..], 12) >> 8) | high_bit;
        const d0 = h0 * r0 + h1 * s4 + h2 * s3 + h3 * s2 + h4 * s1;
        const d1 = h0 * r1 + h1 * r0 + h2 * s4 + h3 * s3 + h4 * s2;
        const d2 = h0 * r2 + h1 * r1 + h2 * r0 + h3 * s4 + h4 * s3;
        const d3 = h0 * r3 + h1 * r2 + h2 * r1 + h3 * r0 + h4 * s4;
        const d4 = h0 * r4 + h1 * r3 + h2 * r2 + h3 * r1 + h4 * r0;
        var carry = d0 >> 26; h0 = d0 & LIMB_MASK;
        const q1 = d1 + carry; carry = q1 >> 26; h1 = q1 & LIMB_MASK;
        const q2 = d2 + carry; carry = q2 >> 26; h2 = q2 & LIMB_MASK;
        const q3 = d3 + carry; carry = q3 >> 26; h3 = q3 & LIMB_MASK;
        const q4 = d4 + carry; carry = q4 >> 26; h4 = q4 & LIMB_MASK;
        h0 += carry * 5;
        carry = h0 >> 26; h0 &= LIMB_MASK; h1 += carry;
        offset += block_length;
    }
    for (0..3) |_| {
        var carry = h0 >> 26; h0 &= LIMB_MASK; h1 += carry;
        carry = h1 >> 26; h1 &= LIMB_MASK; h2 += carry;
        carry = h2 >> 26; h2 &= LIMB_MASK; h3 += carry;
        carry = h3 >> 26; h3 &= LIMB_MASK; h4 += carry;
        carry = h4 >> 26; h4 &= LIMB_MASK; h0 += carry * 5;
        carry = h0 >> 26; h0 &= LIMB_MASK; h1 += carry;
    }
    if (h4 == LIMB_MASK and h3 == LIMB_MASK and h2 == LIMB_MASK and h1 == LIMB_MASK and h0 >= LIMB_MASK - 4) {
        h0 -= LIMB_MASK - 4; h1 = 0; h2 = 0; h3 = 0; h4 = 0;
    }
    const f0 = ((h0 | (h1 << 26)) & 0xffff_ffff) + load32Le(key, 16);
    const f1 = ((h1 >> 6 | (h2 << 20)) & 0xffff_ffff) + load32Le(key, 20) + (f0 >> 32);
    const f2 = ((h2 >> 12 | (h3 << 14)) & 0xffff_ffff) + load32Le(key, 24) + (f1 >> 32);
    const f3 = ((h3 >> 18 | (h4 << 8)) & 0xffff_ffff) + load32Le(key, 28) + (f2 >> 32);
    store32Le(tag, 0, @truncate(f0)); store32Le(tag, 4, @truncate(f1));
    store32Le(tag, 8, @truncate(f2)); store32Le(tag, 12, @truncate(f3));
}

export fn poly1305(input: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 33 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?;
    const raw_length = values[0];
    if (raw_length < 0 or raw_length > @as(i64, @intCast(MAX_MESSAGE_LENGTH))) return -1;
    if (length != 33 + @as(usize, @intCast(raw_length))) return -1;
    for (1..length) |index| if (values[index] < 0 or values[index] > 255) return -1;
    if (output == null or output_capacity < 16) return -2;
    var key = [_]u8{0} ** 32;
    var message = [_]u8{0} ** MAX_MESSAGE_LENGTH;
    var tag = [_]u8{0} ** 16;
    for (0..32) |index| key[index] = @intCast(values[1 + index]);
    for (0..@intCast(raw_length)) |index| message[index] = @intCast(values[33 + index]);
    poly1305Tag(key[0..], message[0..], @intCast(raw_length), tag[0..]);
    const output_ptr = output.?;
    for (0..16) |index| output_ptr[index] = tag[index];
    return 16;
}

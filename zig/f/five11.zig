const MAX_INPUT: usize = 13_523;
const MAX_PARSEABLE_INPUT: usize = 13_524;
const MAX_PACKETS: i64 = 451;

fn readBits(values: [*c]const i64, length: usize, bit_offset: usize, width: usize) ?i64 {
    const bit_length = length * 8;
    if (bit_offset > bit_length or width > bit_length - bit_offset) return null;
    const byte_offset = bit_offset >> 3;
    const start = bit_offset & 7;
    const byte_count = (start + width + 7) >> 3;
    var window: u32 = 0;
    for (0..byte_count) |index| {
        window = (window << 8) | @as(u32, @intCast(values[byte_offset + index]));
    }
    const shift: u5 = @intCast(byte_count * 8 - start - width);
    const mask = (@as(u32, 1) << @as(u5, @intCast(width))) - 1;
    return @as(i64, @intCast((window >> shift) & mask));
}

fn decodeSum(values: [*c]const i64, length: usize) ?i64 {
    const packet_count = readBits(values, length, 0, 16) orelse return null;
    if (packet_count > MAX_PACKETS) return null;
    var bit_offset: usize = 16;
    var total: i64 = 0;
    for (0..@intCast(packet_count)) |_| {
        const channels = readBits(values, length, bit_offset, 5) orelse return null;
        bit_offset += 5;
        for (0..@intCast(channels)) |_| {
            total += readBits(values, length, bit_offset, 11) orelse return null;
            bit_offset += 11;
        }
        const packet_bits = 5 + 11 * @as(usize, @intCast(channels));
        bit_offset += (8 - (packet_bits & 7)) & 7;
        if (bit_offset > length * 8) return null;
    }
    return total;
}

export fn five11(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_PARSEABLE_INPUT or length > MAX_INPUT) return -1;
    for (0..length) |index| {
        if (values[index] < 0 or values[index] > 255) return -1;
    }
    var result: i64 = 0;
    for (0..10_000) |_| {
        result = decodeSum(values, length) orelse return -1;
    }
    return result;
}

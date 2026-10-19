const MAX_BITS: usize = 4096;
const MAX_OPS: usize = 32;
const MAX_OUTPUT: usize = MAX_BITS / 8;
export fn bitmap_block_allocation(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 2 or length > 2 + 2 * MAX_OPS) return -1;
    const raw_bits = values[0]; const raw_ops = values[1];
    if (raw_bits < 1 or raw_bits > MAX_BITS or raw_ops < 0 or raw_ops > MAX_OPS) return -1;
    const bits: usize = @intCast(raw_bits); const ops: usize = @intCast(raw_ops);
    if (length != 2 + 2 * ops) return -1;
    var offsets: [MAX_OPS]usize = @splat(0); var runs: [MAX_OPS]usize = @splat(0);
    for (0..ops) |i| {
        const o = values[2+2*i]; const n = values[3+2*i];
        if (o < 0 or o > raw_bits or n < 0 or n > raw_bits-o) return -1;
        offsets[i] = @intCast(o); runs[i] = @intCast(n);
    }
    var bitmap: [MAX_BITS]bool = @splat(false);
    var b: usize = 0; while (b < bits) : (b += 2) bitmap[b] = true;
    for (0..ops) |i| {
        var pos = offsets[i]; while (pos < offsets[i]+runs[i]) : (pos += 1) {
            if (i%3 == 0) bitmap[pos] = true else if (i%3 == 1) bitmap[pos] = false else bitmap[pos] = !bitmap[pos];
        }
    }
    const byte_count = (bits+7)/8;
    if (output == null or capacity < byte_count) return -2;
    for (0..byte_count) |j| {
        var packed: u8 = 0;
        for (0..8) |bit| { const index=j*8+bit; if (index<bits and bitmap[index]) packed |= @as(u8,1) << @intCast(bit); }
        output[j]=packed;
    }
    return @intCast(byte_count);
}

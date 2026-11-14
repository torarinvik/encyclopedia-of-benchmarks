fn popcountByte(value: u8) usize { return @popCount(value); }

fn decode(cls: usize, offset: usize) u8 {
    var remaining = offset;
    for (0..256) |candidate| {
        if (popcountByte(@intCast(candidate)) == cls) {
            if (remaining == 0) return @intCast(candidate);
            remaining -= 1;
        }
    }
    return 0;
}

pub export fn rrr_class_offset_rank_select(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 35 or input[0] < 1 or input[0] > 63 or input[1] < 0 or input[2] < 0 or input[2] > 16) return -1;
    const n: usize = @intCast(input[0]);
    const bits: u64 = @intCast(input[1]);
    const q: usize = @intCast(input[2]);
    if (bits >> @as(u6, @intCast(n)) != 0 or length != 3+2*q) return -1;
    for (0..q) |i| {
        const op = input[3+2*i]; const index = input[4+2*i];
        if ((op != 0 and op != 1) or index < 1 or (op == 0 and index > @as(i64, @intCast(n))) or (op == 1 and index > 64)) return -1;
    }
    if (output == null or capacity < 8*q) return -2;
    var classes: [8]usize = @splat(0);
    var offsets: [8]usize = @splat(0);
    var prefix: [9]usize = @splat(0);
    const blocks = (n+7)/8;
    for (0..blocks) |block| {
        const byte: u8 = @truncate(bits >> @as(u6, @intCast(8*block)));
        classes[block] = popcountByte(byte);
        for (0..byte) |candidate| {
            if (popcountByte(@intCast(candidate)) == classes[block]) offsets[block] += 1;
        }
        prefix[block+1] = prefix[block]+classes[block];
    }
    for (0..q) |i| {
        const op = input[3+2*i];
        const index: usize = @intCast(input[4+2*i]);
        var answer: i64 = -1;
        if (op == 0) {
            const block = (index-1)/8;
            const byte = decode(classes[block], offsets[block]);
            answer = @intCast(prefix[block]);
            for (0..index-8*block) |bit| answer += @intCast((byte >> @as(u3, @intCast(bit))) & 1);
        } else {
            var block: usize = 0;
            while (block < blocks and prefix[block+1] < index) : (block += 1) {}
            if (block < blocks) {
                var remaining = index-prefix[block];
                const byte = decode(classes[block], offsets[block]);
                for (0..@min(8, n-8*block)) |bit| {
                    if ((byte >> @as(u3, @intCast(bit))) & 1 != 0) {
                        remaining -= 1;
                        if (remaining == 0) { answer = @intCast(8*block+bit+1); break; }
                    }
                }
            }
        }
        var encoded: u64 = @bitCast(answer);
        for (0..8) |byte| { output[8*i+byte] = @truncate(encoded); encoded >>= 8; }
    }
    return @intCast(8*q);
}

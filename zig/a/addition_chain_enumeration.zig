const MAX_TARGET: i64 = 31;
const OUTPUT_BYTES: usize = 24;

const Search = struct {
    target: i64,
    limit: usize,
    chain: [32]i64 = @splat(0),
    total_count: i64 = 0,
    brauer_count: i64 = 0,

    fn visit(self: *Search, length: usize, prefix_is_brauer: bool) void {
        const last = self.chain[length - 1];
        const steps = length - 1;
        if (last == self.target) {
            if (steps == self.limit) {
                self.total_count += 1;
                if (prefix_is_brauer) self.brauer_count += 1;
            }
            return;
        }
        const remaining = self.limit - steps;
        if (remaining == 0 or last * (@as(i64, 1) << @intCast(remaining)) < self.target) return;

        var generated: [32]bool = @splat(false);
        for (0..length) |left| {
            for (left..length) |right| {
                const candidate = self.chain[left] + self.chain[right];
                if (candidate <= last or candidate > self.target or generated[@intCast(candidate)]) continue;
                generated[@intCast(candidate)] = true;
                self.chain[length] = candidate;
                var uses_last = false;
                for (0..length) |index| {
                    if (last + self.chain[index] == candidate) uses_last = true;
                }
                self.visit(length + 1, prefix_is_brauer and uses_last);
            }
        }
    }
};

fn bitLength(value_arg: i64) usize {
    var value = value_arg;
    var count: usize = 0;
    while (value != 0) : (value >>= 1) count += 1;
    return count;
}

fn popcount(value_arg: i64) usize {
    var value = value_arg;
    var count: usize = 0;
    while (value != 0) : (value >>= 1) count += @intCast(value & 1);
    return count;
}

fn minimumCounts(target: i64) [3]i64 {
    if (target == 1) return .{ 0, 1, 0 };
    const lower = bitLength(target - 1);
    const upper = bitLength(target) - 1 + popcount(target) - 1;
    for (lower..upper + 1) |limit| {
        var search = Search{ .target = target, .limit = limit };
        search.chain[0] = 1;
        search.visit(1, true);
        if (search.total_count != 0)
            return .{ @intCast(limit), search.brauer_count, search.total_count - search.brauer_count };
    }
    return .{ 0, 0, 0 };
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn addition_chain_enumeration(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length != 1) return -1;
    const target = input.?[0];
    if (target < 1 or target > MAX_TARGET) return -1;
    const result = minimumCounts(target);
    if (output == null or output_capacity < OUTPUT_BYTES) return -2;
    for (0..result.len) |index| storeI64Le(output.?, index * 8, result[index]);
    return OUTPUT_BYTES;
}

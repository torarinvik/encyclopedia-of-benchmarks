fn previousBucket(index: isize) isize { return (index & (index + 1)) - 1; }

export fn maximum_fenwick_tree(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 194) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 64 or input[1] < 0 or input[1] > 64) return -1;
    const size: usize = @intCast(input[0]);
    const op_count: usize = @intCast(input[1]);
    if (length != 2 + 3 * op_count) return -1;
    var values: [64]i32 = [_]i32{0} ** 64;
    var tree: [64]i32 = [_]i32{0} ** 64;
    var results: [64]i64 = undefined;
    var result_count: usize = 0;
    for (0..op_count) |op| {
        const pos = 2 + 3 * op;
        const opcode = input[pos];
        const first = input[pos + 1];
        const second = input[pos + 2];
        if (opcode == 0) {
            if (first < 0 or first >= @as(i64, @intCast(size)) or second < 0 or second > 2147483647) return -1;
            var index: usize = @intCast(first);
            const old_value = values[index];
            const value: i32 = @intCast(second);
            values[index] = value;
            while (index < size) {
                const old_max = tree[index];
                if (value > old_max) {
                    tree[index] = value;
                } else if (old_value == old_max) {
                    const left: usize = @intCast(previousBucket(@intCast(index)) + 1);
                    var maximum = value;
                    var child: isize = @as(isize, @intCast(index)) - 1;
                    while (child >= @as(isize, @intCast(left))) {
                        maximum = @max(maximum, tree[@intCast(child)]);
                        if (maximum == old_max) break;
                        child = previousBucket(child);
                    }
                    tree[index] = maximum;
                    if (maximum == old_max) break;
                } else break;
                index |= index + 1;
            }
        } else if (opcode == 1) {
            if (first < 0 or first > second or second > @as(i64, @intCast(size))) return -1;
            var maximum: i32 = 0;
            var right = second - 1;
            while (first <= right) {
                const current_left = right & (right + 1);
                if (first <= current_left) {
                    maximum = @max(maximum, tree[@intCast(right)]);
                    right = current_left - 1;
                } else {
                    maximum = @max(maximum, values[@intCast(right)]);
                    right -= 1;
                }
            }
            results[result_count] = maximum;
            result_count += 1;
        } else return -1;
    }
    const bytes = result_count * 8;
    if (output_opt == null or output_capacity < bytes) return -2;
    const output = output_opt.?;
    for (0..result_count) |i| {
        const bits: u64 = @bitCast(results[i]);
        for (0..8) |b| output[8 * i + b] = @intCast((bits >> @intCast(8 * b)) & 255);
    }
    return @intCast(bytes);
}

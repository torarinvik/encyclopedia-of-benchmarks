fn compareStrings(input: [*c]const i64, start_a: usize, len_a: usize, start_b: usize, len_b: usize) i8 {
    const limit = @min(len_a, len_b);
    for (0..limit) |i| {
        if (input[start_a + i] < input[start_b + i]) return -1;
        if (input[start_a + i] > input[start_b + i]) return 1;
    }
    if (len_a < len_b) return -1;
    if (len_a > len_b) return 1;
    return 0;
}

pub export fn longest_common_prefix(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length == 0 or length > 1041 or input[0] < 0 or input[0] > 16) return -1;
    const count: usize = @intCast(input[0]);
    var starts: [16]usize = @splat(0);
    var sizes: [16]usize = @splat(0);
    var position: usize = 1;
    for (0..count) |i| {
        if (position >= length or input[position] < 0 or input[position] > 64) return -1;
        sizes[i] = @intCast(input[position]);
        position += 1;
        if (sizes[i] > length - position) return -1;
        starts[i] = position;
        for (0..sizes[i]) |j| if (input[position + j] < 0 or input[position + j] > 127) return -1;
        position += sizes[i];
    }
    if (position != length) return -1;
    if (count == 0) return 0;
    var order: [16]usize = @splat(0);
    for (0..count) |i| order[i] = i;
    for (1..count) |i| {
        const value = order[i];
        var j = i;
        while (j > 0 and compareStrings(input, starts[order[j - 1]], sizes[order[j - 1]], starts[value], sizes[value]) > 0) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = value;
    }
    const first = order[0]; const last = order[count - 1];
    const limit = @min(sizes[first], sizes[last]);
    var prefix: usize = 0;
    while (prefix < limit and input[starts[first] + prefix] == input[starts[last] + prefix]) : (prefix += 1) {}
    if (capacity < prefix or (prefix > 0 and output == null)) return -2;
    for (0..prefix) |i| output[i] = @intCast(input[starts[first] + i]);
    return @intCast(prefix);
}

const MAX_TEXT_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 65;

fn pairLess(left: usize, right: usize, rank: *const [MAX_TEXT_LENGTH]i64,
    length: usize, step: usize) bool {
    if (rank[left] != rank[right]) return rank[left] < rank[right];
    const leftSecond = if (left + step < length) rank[left + step] else -1;
    const rightSecond = if (right + step < length) rank[right + step] else -1;
    return leftSecond < rightSecond;
}

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn suffix_array(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const count_value = values[0];
    if (count_value < 0 or count_value > @as(i64, @intCast(MAX_TEXT_LENGTH))) return -1;
    const count: usize = @intCast(count_value);
    if (length != 1 + count) return -1;
    for (0..count) |i| {
        const value = values[1 + i];
        if (value < 0 or value > 127) return -1;
    }

    const output_bytes = count * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    if (count == 0) return 0;

    var suffixes: [MAX_TEXT_LENGTH]usize = @splat(0);
    var rank: [MAX_TEXT_LENGTH]i64 = @splat(0);
    var next_rank: [MAX_TEXT_LENGTH]i64 = @splat(0);
    for (0..count) |i| {
        suffixes[i] = i;
        rank[i] = values[1 + i];
    }

    var step: usize = 1;
    while (step < count) : (step *= 2) {
        for (1..count) |i| {
            const key = suffixes[i];
            var position = i;
            while (position > 0 and pairLess(key, suffixes[position - 1], &rank, count, step)) {
                suffixes[position] = suffixes[position - 1];
                position -= 1;
            }
            suffixes[position] = key;
        }
        next_rank[suffixes[0]] = 0;
        for (1..count) |i| {
            const previous = suffixes[i - 1];
            const current = suffixes[i];
            const previousSecond: i64 = if (previous + step < count) rank[previous + step] else -1;
            const currentSecond: i64 = if (current + step < count) rank[current + step] else -1;
            next_rank[current] = next_rank[previous] +
                @as(i64, if (rank[previous] == rank[current] and previousSecond == currentSecond) 0 else 1);
        }
        for (0..count) |i| rank[i] = next_rank[i];
        if (rank[suffixes[count - 1]] == @as(i64, @intCast(count - 1))) break;
    }

    for (0..count) |i| putI64Le(output, i * 8, @intCast(suffixes[i]));
    return @intCast(output_bytes);
}

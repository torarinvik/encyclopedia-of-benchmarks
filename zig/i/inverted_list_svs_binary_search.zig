const MIN_LISTS: usize = 2;
const MAX_LISTS: usize = 8;
const MAX_LIST_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = MAX_LISTS * (MAX_LIST_LENGTH + 1) + 2;
const BYTES_PER_VALUE: usize = 4;

fn storeI32Le(output: [*c]u8, position: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..BYTES_PER_VALUE) |byte| output[position + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
}

export fn inverted_list_svs_binary_search(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < MIN_LISTS + 1 or length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < @as(i64, @intCast(MIN_LISTS)) or input[0] > @as(i64, @intCast(MAX_LISTS))) return -1;
    const count: usize = @intCast(input[0]);
    var starts: [MAX_LISTS]usize = undefined;
    var sizes: [MAX_LISTS]usize = undefined;
    var order: [MAX_LISTS]usize = undefined;
    var position: usize = 1;
    for (0..count) |list| {
        if (position >= length or input[position] < 0 or input[position] > @as(i64, @intCast(MAX_LIST_LENGTH))) return -1;
        const size: usize = @intCast(input[position]); position += 1;
        if (size > length - position) return -1;
        starts[list] = position; sizes[list] = size; order[list] = list;
        for (0..size) |i| {
            const value = input[position + i];
            if (value < -2147483648 or value > 2147483647) return -1;
            if (i > 0 and input[position + i - 1] >= value) return -1;
        }
        position += size;
    }
    if (position != length) return -1;
    for (1..count) |i| {
        const key = order[i]; var j = i;
        while (j > 0 and sizes[order[j - 1]] > sizes[key]) : (j -= 1) order[j] = order[j - 1];
        order[j] = key;
    }
    const maximum_result = sizes[order[0]];
    if (output_capacity < maximum_result * BYTES_PER_VALUE or (maximum_result > 0 and output == null)) return -2;
    var candidates: [MAX_LIST_LENGTH]i32 = @splat(0);
    var candidate_count = maximum_result;
    for (0..candidate_count) |i| candidates[i] = @intCast(input[starts[order[0]] + i]);
    for (1..count) |rank| {
        if (candidate_count == 0) break;
        const list = order[rank]; const start = starts[list]; const size = sizes[list];
        var cursor: usize = 0; var kept: usize = 0;
        for (0..candidate_count) |i| {
            const candidate = candidates[i]; var low = cursor; var high = size;
            while (low < high) {
                const middle = low + (high - low) / 2;
                if (input[start + middle] < @as(i64, candidate)) low = middle + 1 else high = middle;
            }
            if (low < size and input[start + low] == @as(i64, candidate)) {
                candidates[kept] = candidate; kept += 1; cursor = low + 1;
            } else cursor = low;
        }
        candidate_count = kept;
    }
    for (0..candidate_count) |i| storeI32Le(output, i * BYTES_PER_VALUE, candidates[i]);
    return @intCast(candidate_count);
}

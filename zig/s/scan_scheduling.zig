const MAX_REQUESTS: usize = 64;
const MAX_OUTPUT_VALUES: usize = 65;

fn sortAscending(values: *[MAX_REQUESTS]i32, count: usize) void {
    if (count < 2) return;
    for (1..count) |i| {
        const value = values[i];
        var position = i;
        while (position > 0 and values[position - 1] > value) {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = value;
    }
}

fn putI32Le(output: [*c]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn scan_scheduling(input: [*c]const i32, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > 68) return -1;
    const disk_size = input[0];
    const head = input[1];
    const direction = input[2];
    const request_count = input[3];
    if (disk_size < 1 or disk_size > 256 or head < 0 or head >= disk_size or
        (direction != 0 and direction != 1) or request_count < 0 or request_count > MAX_REQUESTS or
        length != 4 + @as(usize, @intCast(request_count))) return -1;

    var left: [MAX_REQUESTS]i32 = @splat(0);
    var right: [MAX_REQUESTS]i32 = @splat(0);
    var left_count: usize = 0;
    var right_count: usize = 0;
    for (0..@intCast(request_count)) |i| {
        const request = input[4 + i];
        if (request < 0 or request >= disk_size) return -1;
        if (request < head) {
            left[left_count] = request;
            left_count += 1;
        } else {
            right[right_count] = request;
            right_count += 1;
        }
    }
    sortAscending(&left, left_count);
    sortAscending(&right, right_count);

    var ordered: [MAX_OUTPUT_VALUES]i32 = @splat(0);
    var count: usize = 0;
    if (request_count > 0) {
        if (direction == 1) {
            for (0..right_count) |i| { ordered[count] = right[i]; count += 1; }
            ordered[count] = disk_size - 1;
            count += 1;
            var i = left_count;
            while (i > 0) { i -= 1; ordered[count] = left[i]; count += 1; }
        } else {
            var i = left_count;
            while (i > 0) { i -= 1; ordered[count] = left[i]; count += 1; }
            ordered[count] = 0;
            count += 1;
            for (0..right_count) |i| { ordered[count] = right[i]; count += 1; }
        }
    }
    const bytes = count * 4;
    if (output == null or capacity < bytes) return -2;
    for (0..count) |i| putI32Le(output, i * 4, ordered[i]);
    return @intCast(bytes);
}

const MAX_LENGTH: usize = 256;

fn readI32Le(buffer: []const u8, index: usize) i32 {
    const offset = index * 4;
    const bits: u32 = @as(u32, buffer[offset])
        | (@as(u32, buffer[offset + 1]) << 8)
        | (@as(u32, buffer[offset + 2]) << 16)
        | (@as(u32, buffer[offset + 3]) << 24);
    return @bitCast(bits);
}

fn writeI32Le(buffer: []u8, index: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    const offset = index * 4;
    for (0..4) |byte| buffer[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn merge(buffer: []u8, start: usize, middle: usize, end: usize, max_element: i32) void {
    var i = start;
    var j = middle + 1;
    var k = start;
    while (i <= middle and j <= end) {
        const left = @rem(readI32Le(buffer, i), max_element);
        const right = @rem(readI32Le(buffer, j), max_element);
        const current = readI32Le(buffer, k);
        if (left <= right) {
            writeI32Le(buffer, k, current + left * max_element);
            i += 1;
        } else {
            writeI32Le(buffer, k, current + right * max_element);
            j += 1;
        }
        k += 1;
    }
    while (i <= middle) : (i += 1) {
        const current = readI32Le(buffer, k);
        const next = @rem(readI32Le(buffer, i), max_element);
        writeI32Le(buffer, k, current + next * max_element);
        k += 1;
    }
    while (j <= end) : (j += 1) {
        const current = readI32Le(buffer, k);
        const next = @rem(readI32Le(buffer, j), max_element);
        writeI32Le(buffer, k, current + next * max_element);
        k += 1;
    }
    for (start..end + 1) |index|
        writeI32Le(buffer, index, @divTrunc(readI32Le(buffer, index), max_element));
}

fn mergeSort(buffer: []u8, start: usize, end: usize, max_element: i32) void {
    if (start >= end) return;
    const middle = start + (end - start) / 2;
    mergeSort(buffer, start, middle, max_element);
    mergeSort(buffer, middle + 1, end, max_element);
    merge(buffer, start, middle, end, max_element);
}

export fn merge_sort_no_extra_space(values_opt: ?[*]const i32, length: usize, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (values_opt == null or length > MAX_LENGTH) return -1;
    const values = values_opt.?;
    var max_value: i32 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > 32767) return -1;
        max_value = @max(max_value, value);
    }
    const output_bytes = length * 4;
    if (output_opt == null or output_capacity < output_bytes) return -2;
    const output = output_opt.?[0..output_bytes];
    for (0..length) |index| writeI32Le(output, index, values[index]);
    if (length > 1) mergeSort(output, 0, length - 1, max_value + 1);
    return @intCast(output_bytes);
}

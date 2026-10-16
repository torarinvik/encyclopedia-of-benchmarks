const MAX_VALUES: usize = 4096;

fn merge_pass(source: [*]const i64, destination: [*]i64, length: usize, width: usize) void {
    var start: usize = 0;
    while (start < length) : (start += width * 2) {
        const middle = @min(start + width, length);
        const end = @min(middle + width, length);
        var left = start;
        var right = middle;
        var output = start;
        while (left < middle and right < end) {
            if (source[left] < source[right]) {
                destination[output] = source[left];
                left += 1;
            } else {
                destination[output] = source[right];
                right += 1;
            }
            output += 1;
        }
        while (left < middle) : (left += 1) { destination[output] = source[left]; output += 1; }
        while (right < end) : (right += 1) { destination[output] = source[right]; output += 1; }
    }
}

export fn external_merge_sorter(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (length > MAX_VALUES or (length != 0 and values == null)) return -1;
    const output_bytes = length * 8;
    if (output == null or output_capacity < output_bytes) return -2;

    var primary: [MAX_VALUES]i64 = undefined;
    var temporary: [MAX_VALUES]i64 = undefined;
    for (0..length) |index| primary[index] = values[index];
    var primary_is_source = true;
    var width: usize = 1;
    while (width < length) {
        if (primary_is_source) {
            merge_pass(&primary, &temporary, length, width);
        } else {
            merge_pass(&temporary, &primary, length, width);
        }
        primary_is_source = !primary_is_source;
        if (width > length / 2) break;
        width *= 2;
    }
    for (0..length) |index| {
        const value = if (primary_is_source) primary[index] else temporary[index];
        const bits: u64 = @bitCast(value);
        for (0..8) |byte| output[index * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(output_bytes);
}

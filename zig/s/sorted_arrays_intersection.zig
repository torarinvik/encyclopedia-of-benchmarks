/// Intersect three strictly increasing arrays and emit ascending signed i32 values.
const ARRAY_COUNT: usize = 3;
const MAX_ARRAY_LENGTH: usize = 64;
const BYTES_PER_VALUE: usize = 4;

fn storeI32Le(output: [*c]u8, position: usize, value: i64) void {
    const bits: u32 = @truncate(@as(u64, @bitCast(value)));
    for (0..BYTES_PER_VALUE) |byte|
        output[position + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn sorted_arrays_intersection(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < ARRAY_COUNT or length > ARRAY_COUNT * (MAX_ARRAY_LENGTH + 1)) return -1;
    var starts: [ARRAY_COUNT]usize = undefined;
    var sizes: [ARRAY_COUNT]usize = undefined;
    var position: usize = 0;
    for (0..ARRAY_COUNT) |array| {
        if (position >= length or input[position] < 0 or input[position] > MAX_ARRAY_LENGTH) return -1;
        const size: usize = @intCast(input[position]);
        position += 1;
        if (size > length - position) return -1;
        starts[array] = position;
        sizes[array] = size;
        for (0..size) |index| {
            const value = input[position + index];
            if (value < -2147483648 or value > 2147483647) return -1;
            if (index > 0 and input[position + index - 1] >= value) return -1;
        }
        position += size;
    }
    if (position != length) return -1;
    const maximum_result = @min(sizes[0], @min(sizes[1], sizes[2]));
    if (output_capacity < maximum_result * BYTES_PER_VALUE or
        (maximum_result > 0 and output == null)) return -2;

    var cursor: [ARRAY_COUNT]usize = @splat(0);
    var result_count: usize = 0;
    while (cursor[0] < sizes[0] and cursor[1] < sizes[1] and cursor[2] < sizes[2]) {
        const first = input[starts[0] + cursor[0]];
        const second = input[starts[1] + cursor[1]];
        const third = input[starts[2] + cursor[2]];
        if (first == second and first == third) {
            storeI32Le(output, result_count * BYTES_PER_VALUE, first);
            result_count += 1;
            cursor[0] += 1; cursor[1] += 1; cursor[2] += 1;
        } else if (first < second) {
            cursor[0] += 1;
        } else if (second < third) {
            cursor[1] += 1;
        } else {
            cursor[2] += 1;
        }
    }
    return @intCast(result_count);
}

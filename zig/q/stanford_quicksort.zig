const SORT_ELEMENTS: usize = 5000;
const MAX_PREFIX_COUNT: i64 = 100;
const MAX_OUTPUT_BYTES: usize = 700;

fn sourceQuicksort(values: []i64, left_value: isize, right_value: isize) void {
    var i = left_value;
    var j = right_value;
    const pivot = values[@intCast(@divTrunc(left_value + right_value, 2))];
    while (true) {
        while (values[@intCast(i)] < pivot) i += 1;
        while (pivot < values[@intCast(j)]) j -= 1;
        if (i <= j) {
            const temporary = values[@intCast(i)];
            values[@intCast(i)] = values[@intCast(j)];
            values[@intCast(j)] = temporary;
            i += 1;
            j -= 1;
        }
        if (i > j) break;
    }
    if (left_value < j) sourceQuicksort(values, left_value, j);
    if (i < right_value) sourceQuicksort(values, i, right_value);
}

fn appendNumber(buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize, value_value: i64) void {
    var value = value_value;
    if (value < 0) {
        buffer[used.*] = '-';
        used.* += 1;
        value = -value;
    }
    var reversed: [20]u8 = undefined;
    var count: usize = 0;
    while (true) {
        reversed[count] = @intCast('0' + @mod(value, 10));
        count += 1;
        value = @divTrunc(value, 10);
        if (value == 0) break;
    }
    while (count > 0) {
        count -= 1;
        buffer[used.*] = reversed[count];
        used.* += 1;
    }
    buffer[used.*] = '\n';
    used.* += 1;
}

export fn stanford_quicksort(prefix_count: i64, output_opt: ?[*]u8,
    output_capacity: usize) i64 {
    if (prefix_count < 1 or prefix_count > MAX_PREFIX_COUNT) return -1;
    if (output_opt == null) return -2;

    var staged: [MAX_OUTPUT_BYTES]u8 = undefined;
    var used: usize = 0;
    for (0..@intCast(prefix_count)) |run| {
        var values: [SORT_ELEMENTS + 1]i64 = undefined;
        var state: i64 = 74755;
        for (1..SORT_ELEMENTS + 1) |index| {
            state = @mod(state * 1309 + 13849, 65536);
            values[index] = state - 50000;
        }
        sourceQuicksort(values[0..], 1, SORT_ELEMENTS);
        appendNumber(&staged, &used, values[run + 1]);
    }

    if (output_capacity < used) return -2;
    const output = output_opt.?;
    for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}

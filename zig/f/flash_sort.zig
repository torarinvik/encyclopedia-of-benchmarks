/// Bounded Flash Sort followed by the source's insertion-sort finishing pass.
const MAX_LENGTH: usize = 64;

fn validLength(length: usize) bool { return length <= 1 or (length >= 3 and length <= MAX_LENGTH); }
fn classOf(value: i64, minimum: i64, range: i64, classes: usize) usize {
    return @intCast((@as(i64, @intCast(classes - 1)) * (value - minimum)) / range);
}
fn flashSortValues(values: *[MAX_LENGTH]i64, length: usize) bool {
    if (length <= 1) return true;
    var minimum = values[0];
    var maximum = values[0];
    for (1..length) |index| {
        if (values[index] < minimum) minimum = values[index];
        if (values[index] > maximum) maximum = values[index];
    }
    if (minimum == maximum) return true;
    const range = maximum - minimum;
    const classes = @max(1, (9 * length) / 20);
    var class_ends = [_]usize{0} ** MAX_LENGTH;
    for (0..length) |index| class_ends[classOf(values[index], minimum, range, classes)] += 1;
    for (1..classes) |index| class_ends[index] += class_ends[index - 1];
    var moves: usize = 0;
    var j: usize = 0;
    var k = classes - 1;
    while (moves < length - 1) {
        while (j > class_ends[k] - 1) {
            j += 1;
            if (j >= length) return false;
            k = classOf(values[j], minimum, range, classes);
        }
        var flash = values[j];
        while (j != class_ends[k]) {
            k = classOf(flash, minimum, range, classes);
            class_ends[k] -= 1;
            const target = class_ends[k];
            const hold = values[target];
            values[target] = flash;
            flash = hold;
            moves += 1;
        }
    }
    for (1..length) |index| {
        const key = values[index];
        var cursor = index;
        while (cursor > 0 and values[cursor - 1] > key) {
            values[cursor] = values[cursor - 1];
            cursor -= 1;
        }
        values[cursor] = key;
    }
    return true;
}

export fn flash_sort(input: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (length > 65 or !validLength(length) or (length != 0 and input == null)) return -1;
    var values: [MAX_LENGTH]i64 = undefined;
    const input_values = input orelse undefined;
    for (0..length) |index| {
        if (input_values[index] < -1000000 or input_values[index] > 1000000) return -1;
        values[index] = input_values[index];
    }
    const output_bytes = length * 4;
    if (output_capacity < output_bytes or (output_bytes != 0 and output == null)) return -2;
    if (!flashSortValues(&values, length)) return -1;
    const output_values = output orelse undefined;
    for (0..length) |index| {
        const bits: u32 = @bitCast(@as(i32, @intCast(values[index])));
        for (0..4) |byte| output_values[index * 4 + byte] = @truncate(bits >> @intCast(8 * byte));
    }
    return @intCast(output_bytes);
}

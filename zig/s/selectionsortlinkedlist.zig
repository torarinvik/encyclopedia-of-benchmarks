/// Pointer-relinking selection sort modeled with bounded node indices.
const MAX_COUNT: usize = 64;
const MAX_INPUT_LENGTH: usize = 66;

fn selectionSortLinks(values: []const i32, next: []i32, head: *i32) void {
    var minimum = head.*;
    var current = next[@intCast(minimum)];
    var previous = minimum;
    var sorted_tail: i32 = -1;
    while (next[@intCast(minimum)] != -1) {
        while (current != -1) {
            if (values[@intCast(current)] < values[@intCast(minimum)]) {
                if (sorted_tail == -1) {
                    if (previous == minimum) {
                        head.* = current;
                        next[@intCast(minimum)] = next[@intCast(current)];
                        next[@intCast(current)] = previous;
                        minimum = current;
                        current = next[@intCast(previous)];
                    } else {
                        head.* = current;
                        next[@intCast(previous)] = next[@intCast(current)];
                        next[@intCast(current)] = minimum;
                        minimum = current;
                        current = next[@intCast(previous)];
                    }
                } else {
                    next[@intCast(sorted_tail)] = current;
                    next[@intCast(previous)] = next[@intCast(current)];
                    next[@intCast(current)] = minimum;
                    minimum = current;
                    current = next[@intCast(previous)];
                }
            } else {
                previous = next[@intCast(previous)];
                current = next[@intCast(current)];
            }
        }
        sorted_tail = minimum;
        minimum = next[@intCast(minimum)];
        previous = minimum;
        current = next[@intCast(minimum)];
    }
}

fn writeI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn selectionsortlinkedlist(input: ?[*]const i64, length: usize,
                                  output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const values_input = input.?;
    const raw_count = values_input[0];
    if (raw_count < 1 or raw_count > 64 or length != 1 + @as(usize, @intCast(raw_count))) return -1;
    const count: usize = @intCast(raw_count);
    var values: [MAX_COUNT]i32 = @splat(0);
    var next: [MAX_COUNT]i32 = @splat(-1);
    for (0..count) |index| {
        const value = values_input[index + 1];
        if (value < -2147483648 or value > 2147483647) return -1;
        values[index] = @intCast(value);
        next[index] = if (index + 1 < count) @intCast(index + 1) else -1;
    }
    const byte_count = 4 * count;
    if (output == null or output_capacity < byte_count) return -2;

    var head: i32 = 0;
    selectionSortLinks(values[0..], next[0..], &head);
    const output_bytes = output.?;
    var node = head;
    for (0..count) |index| {
        writeI32Le(output_bytes, 4 * index, values[@intCast(node)]);
        node = next[@intCast(node)];
    }
    return @intCast(byte_count);
}

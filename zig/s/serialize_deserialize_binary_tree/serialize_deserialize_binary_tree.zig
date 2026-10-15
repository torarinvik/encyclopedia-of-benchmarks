const std = @import("std");
const MAX_INPUT: usize = 2200;
const MAX_NODES: usize = 127;

fn asciiSpace(value: i64) bool { return value == 32 or (value >= 9 and value <= 13); }

fn parseInteger(input: [*]const i64, first_arg: usize, last_arg: usize) ?i32 {
    var first = first_arg;
    var last = last_arg;
    while (first < last and asciiSpace(input[first])) : (first += 1) {}
    while (last > first and asciiSpace(input[last - 1])) : (last -= 1) {}
    if (first == last) return null;
    var negative = false;
    if (input[first] == 45 or input[first] == 43) { negative = input[first] == 45; first += 1; }
    if (first == last) return null;
    const limit: i64 = if (negative) 2_147_483_648 else 2_147_483_647;
    var magnitude: i64 = 0;
    for (first..last) |index| {
        const digit = input[index];
        if (digit < 48 or digit > 57) return null;
        const value = digit - 48;
        if (magnitude > @divTrunc(limit - value, 10)) return null;
        magnitude = magnitude * 10 + value;
    }
    const signed = if (negative) -magnitude else magnitude;
    return @intCast(signed);
}

export fn serialize_deserialize_binary_tree(values: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length == 0 or length > MAX_INPUT) return -1;
    const input = values.?;
    for (input[0..length]) |value| if (value < 0 or value > 127) return -1;
    var encoded: [MAX_INPUT]u8 = undefined;
    var written: usize = 0;
    var position: usize = 0;
    var slots: usize = 1;
    var nodes: usize = 0;
    while (position < length) {
        if (slots == 0) return -1;
        const start = position;
        while (position < length and input[position] != 44) : (position += 1) {}
        const finish = position;
        if (start == finish) return -1;
        const is_null = finish - start == 4 and input[start] == 110 and input[start + 1] == 117 and input[start + 2] == 108 and input[start + 3] == 108;
        if (written > 0) { encoded[written] = 44; written += 1; }
        if (is_null) {
            @memcpy(encoded[written .. written + 4], "null");
            written += 4;
        } else {
            const number = parseInteger(input, start, finish) orelse return -1;
            nodes += 1;
            if (nodes > MAX_NODES) return -1;
            var number_buf: [12]u8 = undefined;
            const number_text = std.fmt.bufPrint(&number_buf, "{d}", .{number}) catch return -1;
            @memcpy(encoded[written .. written + number_text.len], number_text);
            written += number_text.len;
        }
        slots -= 1;
        if (!is_null) slots += 2;
        if (position < length) { position += 1; if (position == length) return -1; }
    }
    if (slots != 0) return -1;
    if (output == null or output_capacity < written) return -2;
    @memcpy(output.?[0..written], encoded[0..written]);
    return @intCast(written);
}

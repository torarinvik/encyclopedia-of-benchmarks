const std = @import("std");
const MAX_TEXT_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 66;
const MAX_SYMBOLS: usize = 10;
const MAX_OUTPUT_BYTES: usize = 111;

const Frame = struct { start: usize, end: usize, bits: u16, length: usize };

export fn shannon_fano_generate_codes(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    const null_empty = input == null and input_length == 0;
    if (input == null and !null_empty) return -1;
    var text = [_]u8{0} ** MAX_TEXT_LENGTH;
    var text_length: usize = 0;
    if (!null_empty) {
        const values = input.?;
        if (input_length < 1 or input_length > MAX_INPUT_LENGTH) return -1;
        const length_value = values[0];
        if (length_value < 0 or length_value > 64) return -1;
        text_length = @intCast(length_value);
        if (input_length != 1 + text_length) return -1;
        for (0..text_length) |index| {
            const code = values[1 + index];
            if (code < 0 or code > 127) return -1;
            text[index] = @intCast(code);
        }
    }

    var frequencies = [_]usize{0} ** 128;
    for (text[0..text_length]) |symbol| frequencies[symbol] += 1;
    var symbols = [_]usize{0} ** 128;
    var symbol_count: usize = 0;
    for (0..128) |symbol| {
        if (frequencies[symbol] != 0) {
            symbols[symbol_count] = symbol;
            symbol_count += 1;
        }
    }
    if (symbol_count > MAX_SYMBOLS) return -1;
    for (0..symbol_count) |left| {
        for (left + 1..symbol_count) |right| {
            if (frequencies[symbols[left]] == frequencies[symbols[right]]) return -1;
        }
    }
    for (1..symbol_count) |index| {
        const value = symbols[index];
        var position = index;
        while (position > 0 and frequencies[symbols[position - 1]] < frequencies[value]) : (position -= 1) {
            symbols[position] = symbols[position - 1];
        }
        symbols[position] = value;
    }

    var code_bits = [_]u16{0} ** 128;
    var code_lengths = [_]usize{0} ** 128;
    if (symbol_count == 1) {
        code_lengths[symbols[0]] = 1;
    } else if (symbol_count > 1) {
        var stack = [_]Frame{.{ .start = 0, .end = 0, .bits = 0, .length = 0 }} ** 20;
        var stack_length: usize = 1;
        stack[0] = .{ .start = 0, .end = symbol_count - 1, .bits = 0, .length = 0 };
        while (stack_length > 0) {
            stack_length -= 1;
            const frame = stack[stack_length];
            if (frame.start == frame.end) {
                const symbol = symbols[frame.start];
                code_bits[symbol] = frame.bits;
                code_lengths[symbol] = frame.length;
                continue;
            }
            var total: usize = 0;
            for (frame.start..frame.end + 1) |index| total += frequencies[symbols[index]];
            var left_sum: usize = 0;
            var best_difference = std.math.maxInt(usize);
            var split = frame.start;
            for (frame.start..frame.end) |index| {
                left_sum += frequencies[symbols[index]];
                const right_sum = total - left_sum;
                const difference = if (left_sum >= right_sum) left_sum - right_sum else right_sum - left_sum;
                if (difference < best_difference) {
                    best_difference = difference;
                    split = index;
                }
            }
            const next_length = frame.length + 1;
            stack[stack_length] = .{ .start = split + 1, .end = frame.end,
                .bits = (frame.bits << 1) | 1, .length = next_length };
            stack_length += 1;
            stack[stack_length] = .{ .start = frame.start, .end = split,
                .bits = frame.bits << 1, .length = next_length };
            stack_length += 1;
        }
    }

    var bytes = [_]u8{0} ** MAX_OUTPUT_BYTES;
    var written: usize = 0;
    bytes[written] = @intCast(symbol_count);
    written += 1;
    for (0..128) |symbol| {
        const length = code_lengths[symbol];
        if (length == 0) continue;
        bytes[written] = @intCast(symbol);
        bytes[written + 1] = @intCast(length);
        written += 2;
        for (0..length) |offset| {
            const bit = (code_bits[symbol] >> @intCast(length - 1 - offset)) & 1;
            bytes[written] = '0' + @as(u8, @intCast(bit));
            written += 1;
        }
    }
    const destination = output orelse return -2;
    if (output_capacity < written) return -2;
    @memcpy(destination[0..written], bytes[0..written]);
    return @intCast(written);
}

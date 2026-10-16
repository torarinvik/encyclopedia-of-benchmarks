const MAX_TEXT_BYTES: usize = 512;
const MAX_MASK_BYTES: usize = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 531;
const MAX_OUTPUT_BYTES: usize = 1447;

const WORDS = [_][]const u8{ "birds", "market", "street" };
const NORMALIZED_VARIANTS = [_][]const u8{
    "birds", "BIRDS", "Birds", "market", "MARKET", "Market",
    "street", "STREET", "Street",
};

fn isWord(value: u8) bool {
    return (value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z') or
        (value >= '0' and value <= '9') or value == '_';
}

fn isNormalizedTarget(token: []const u8) bool {
    for (NORMALIZED_VARIANTS) |variant| {
        if (std.mem.eql(u8, token, variant)) return true;
    }
    return false;
}

fn matchLength(text: []const u8, start: usize, end: usize, position: usize) usize {
    for (WORDS) |word| {
        const word_length = word.len;
        if (position + word_length <= end and
            std.mem.eql(u8, text[position .. position + word_length], word) and
            (position == start or !isWord(text[position - 1])) and
            (position + word_length == end or !isWord(text[position + word_length])))
        {
            return word_length;
        }
    }
    return 0;
}

fn appendToken(text: []const u8, start: usize, end: usize, mask: []const u8,
    output: []u8, written_value: usize) usize {
    var written = written_value;
    if (isNormalizedTarget(text[start..end])) {
        for (mask) |byte| {
            output[written] = byte;
            written += 1;
        }
        return written;
    }
    var position = start;
    while (position < end) {
        const matched = matchLength(text, start, end, position);
        if (matched != 0) {
            for (mask) |byte| {
                output[written] = byte;
                written += 1;
            }
            position += matched;
        } else {
            if (text[position] != '\n') {
                output[written] = text[position];
                written += 1;
            }
            position += 1;
        }
    }
    return written;
}

const std = @import("std");

export fn maskwords(values: ?[*]const i64, length: usize, output: ?[*]u8,
    output_capacity: usize) i64 {
    if (values == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = values.?;
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_TEXT_BYTES))) return -1;
    const text_length: usize = @intCast(input[0]);
    const mask_length_index = 1 + text_length;
    if (mask_length_index >= length or input[mask_length_index] < 0 or
        input[mask_length_index] > @as(i64, @intCast(MAX_MASK_BYTES))) return -1;
    const mask_length: usize = @intCast(input[mask_length_index]);
    if (length != mask_length_index + 1 + mask_length) return -1;

    var text_storage: [MAX_TEXT_BYTES]u8 = undefined;
    var mask_storage: [MAX_MASK_BYTES]u8 = undefined;
    for (0..text_length) |i| {
        const value = input[1 + i];
        if (value < 1 or value > 127) return -1;
        text_storage[i] = @intCast(value);
    }
    for (0..mask_length) |i| {
        const value = input[mask_length_index + 1 + i];
        if (value < 32 or value > 126 or value == '\\') return -1;
        mask_storage[i] = @intCast(value);
    }
    const text = text_storage[0..text_length];
    const mask = mask_storage[0..mask_length];

    var scratch: [MAX_OUTPUT_BYTES]u8 = undefined;
    var written: usize = 0;
    var start: usize = 0;
    var have_token = false;
    for (0..text_length) |i| {
        if (text[i] == ' ') {
            if (have_token) {
                scratch[written] = ' ';
                written += 1;
            }
            written = appendToken(text, start, i, mask, &scratch, written);
            have_token = true;
            start = i + 1;
        }
    }
    if (start < text_length) {
        if (have_token) {
            scratch[written] = ' ';
            written += 1;
        }
        written = appendToken(text, start, text_length, mask, &scratch, written);
    }
    if (written > MAX_OUTPUT_BYTES) return -1;
    if (output_capacity < written or (written != 0 and output == null)) return -2;
    if (written != 0) {
        const destination = output.?;
        for (0..written) |i| destination[i] = scratch[i];
    }
    return @intCast(written);
}

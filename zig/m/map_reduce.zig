/// Count bounded ASCII tokens in insertion order, matching the pinned Java routine.
const MAX_INPUT: usize = 256;
const MAX_WORDS: usize = 128;
const TABLE_SIZE: usize = 512;

fn isSpaceByte(value: i64) bool {
    return value == 9 or value == 10 or value == 11 or value == 12 or value == 13 or value == 32;
}

fn tokenHash(input: [*c]const i64, start: usize, length: usize) usize {
    var hash: usize = 0;
    for (0..length) |offset| {
        hash = (hash * 31 + @as(usize, @intCast(input[start + offset]))) % 1_000_003;
    }
    return hash;
}

fn tokenEqual(input: [*c]const i64, start: usize, length: usize,
              other_start: usize, other_length: usize) bool {
    if (length != other_length) return false;
    for (0..length) |offset| {
        if (input[start + offset] != input[other_start + offset]) return false;
    }
    return true;
}

fn writeCount(output: [*c]u8, position_value: usize, count_value: usize) usize {
    var digits: [3]u8 = undefined;
    var digit_count: usize = 0;
    var count = count_value;
    while (true) {
        digits[digit_count] = @intCast('0' + count % 10);
        digit_count += 1;
        count /= 10;
        if (count == 0) break;
    }
    var position = position_value;
    while (digit_count != 0) {
        digit_count -= 1;
        output[position] = digits[digit_count];
        position += 1;
    }
    return position;
}

export fn map_reduce(input: [*c]const i64, length: usize,
                     output: [*c]u8, output_capacity: usize) i64 {
    if (length > MAX_INPUT or (length != 0 and input == null)) return -1;
    for (0..length) |index| {
        const value = input[index];
        if (!isSpaceByte(value) and (value < 32 or value > 126)) return -1;
    }

    var starts: [MAX_WORDS]usize = [_]usize{0} ** MAX_WORDS;
    var lengths: [MAX_WORDS]usize = [_]usize{0} ** MAX_WORDS;
    var counts: [MAX_WORDS]usize = [_]usize{0} ** MAX_WORDS;
    var table: [TABLE_SIZE]usize = [_]usize{0} ** TABLE_SIZE;
    var unique_count: usize = 0;
    var begin: usize = 0;
    var end = length;
    while (begin < end and input[begin] <= 32) : (begin += 1) {}
    while (end > begin and input[end - 1] <= 32) : (end -= 1) {}

    if (begin == end) {
        starts[0] = 0; lengths[0] = 0; counts[0] = 1; unique_count = 1;
        table[0] = 1;
    } else {
        var cursor = begin;
        while (cursor < end) {
            while (cursor < end and isSpaceByte(input[cursor])) : (cursor += 1) {}
            if (cursor == end) break;
            const start = cursor;
            while (cursor < end and !isSpaceByte(input[cursor])) : (cursor += 1) {}
            const token_length = cursor - start;
            var slot = tokenHash(input, start, token_length) % TABLE_SIZE;
            while (table[slot] != 0) {
                const item = table[slot] - 1;
                if (tokenEqual(input, start, token_length, starts[item], lengths[item])) {
                    counts[item] += 1;
                    break;
                }
                slot = (slot + 1) % TABLE_SIZE;
            }
            if (table[slot] == 0) {
                starts[unique_count] = start;
                lengths[unique_count] = token_length;
                counts[unique_count] = 1;
                table[slot] = unique_count + 1;
                unique_count += 1;
            }
        }
    }

    var required: usize = 0;
    for (0..unique_count) |item| {
        var digits: usize = 1;
        var value = counts[item];
        while (value >= 10) : (value /= 10) { digits += 1; }
        required += lengths[item] + 2 + digits + @intFromBool(item != 0);
    }
    if (output == null or output_capacity < required) return -2;

    var written: usize = 0;
    for (0..unique_count) |item| {
        if (item != 0) { output[written] = ','; written += 1; }
        for (0..lengths[item]) |offset| {
            output[written] = @intCast(input[starts[item] + offset]);
            written += 1;
        }
        output[written] = ':'; written += 1;
        output[written] = ' '; written += 1;
        written = writeCount(output, written, counts[item]);
    }
    return @intCast(written);
}

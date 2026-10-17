const MAX_KEYS: usize = 4;
const MAX_KEY_LENGTH: usize = 32;
const MAX_MESSAGE_LENGTH: usize = 256;
const MAX_INPUT_LENGTH: usize = 3 + MAX_KEYS + MAX_KEYS * MAX_KEY_LENGTH + MAX_MESSAGE_LENGTH;
const MAX_OUTPUT_LENGTH: usize = 2 * MAX_MESSAGE_LENGTH - 1;

fn isAsciiLetter(value: i64) bool {
    return (value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z');
}

fn normalize(input: []const u8, output: []u8) usize {
    var count: usize = 0;
    for (input) |byte| {
        const upper = if (byte >= 'a' and byte <= 'z') byte - 32 else byte;
        if (upper >= 'A' and upper <= 'Z') {
            output[count] = upper;
            count += 1;
        }
    }
    return count;
}

fn columnOrder(key: []const u8, order: []usize) void {
    for (0..key.len) |index| order[index] = index;
    for (1..key.len) |index| {
        const column = order[index];
        var position = index;
        while (position > 0 and key[order[position - 1]] > key[column]) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = column;
    }
}

fn encryptRound(text: []const u8, key: []const u8, output: []u8) usize {
    var order: [MAX_KEY_LENGTH]usize = undefined;
    var columns: [MAX_MESSAGE_LENGTH]u8 = undefined;
    columnOrder(key, order[0..key.len]);
    var ordered_length: usize = 0;
    for (0..key.len) |rank| {
        var position = order[rank];
        while (position < text.len) : (position += key.len) {
            columns[ordered_length] = text[position];
            ordered_length += 1;
        }
    }
    const group_size = (text.len + key.len - 1) / key.len;
    var output_length: usize = 0;
    for (0..ordered_length) |index| {
        output[output_length] = columns[index];
        output_length += 1;
        if ((index + 1) % group_size == 0 and index + 1 < ordered_length) {
            output[output_length] = ' ';
            output_length += 1;
        }
    }
    return output_length;
}

fn decryptRound(text: []const u8, key: []const u8, output: []u8) usize {
    var order: [MAX_KEY_LENGTH]usize = undefined;
    var columns: [MAX_KEY_LENGTH][MAX_MESSAGE_LENGTH]u8 = undefined;
    var column_lengths: [MAX_KEY_LENGTH]usize = @splat(0);
    columnOrder(key, order[0..key.len]);
    const short_length = text.len / key.len;
    const longer_columns = text.len % key.len;
    var cursor: usize = 0;
    for (0..key.len) |rank| {
        const column = order[rank];
        const column_length = short_length + @intFromBool(column < longer_columns);
        column_lengths[column] = column_length;
        for (0..column_length) |row| {
            columns[column][row] = text[cursor];
            cursor += 1;
        }
    }
    const row_count = short_length + @intFromBool(longer_columns > 0);
    var output_length: usize = 0;
    for (0..row_count) |row| {
        for (0..key.len) |column| {
            if (row < column_lengths[column]) {
                output[output_length] = columns[column][row];
                output_length += 1;
            }
        }
    }
    return output_length;
}

fn hashOutput(text: []const u8) i64 {
    var hash: u64 = 14695981039346656037;
    var length_bits: u64 = @intCast(text.len);
    for (0..8) |_| {
        hash = (hash ^ (length_bits & 255)) *% 1099511628211;
        length_bits >>= 8;
    }
    for (text) |byte| {
        var codepoint: u32 = byte;
        for (0..4) |_| {
            hash = (hash ^ (codepoint & 255)) *% 1099511628211;
            codepoint >>= 8;
        }
    }
    return @intCast(hash & 0x7fff_ffff_ffff_ffff);
}

export fn transposition_rust(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?;
    const mode = values[0];
    const key_count_value = values[1];
    if ((mode != 0 and mode != 1) or key_count_value < 1 or key_count_value > @as(i64, MAX_KEYS)) return -1;
    const key_count: usize = @intCast(key_count_value);

    var keys: [MAX_KEYS][MAX_KEY_LENGTH]u8 = @splat(@splat(0));
    var key_lengths: [MAX_KEYS]usize = @splat(0);
    var longest_key: usize = 0;
    var cursor: usize = 2;
    for (0..key_count) |key_index| {
        if (cursor >= length) return -1;
        const key_length_value = values[cursor];
        cursor += 1;
        if (key_length_value < 1 or key_length_value > @as(i64, MAX_KEY_LENGTH)) return -1;
        const key_length: usize = @intCast(key_length_value);
        if (key_length > length - cursor) return -1;
        for (0..key_length) |index| {
            const value = values[cursor + index];
            if (!isAsciiLetter(value)) return -1;
            const byte: u8 = @intCast(value);
            keys[key_index][index] = if (byte >= 'a' and byte <= 'z') byte - 32 else byte;
        }
        cursor += key_length;
        key_lengths[key_index] = key_length;
        longest_key = @max(longest_key, key_length);
    }
    if (cursor >= length) return -1;
    const message_length_value = values[cursor];
    cursor += 1;
    if (message_length_value < 1 or message_length_value > @as(i64, MAX_MESSAGE_LENGTH)) return -1;
    const message_length: usize = @intCast(message_length_value);
    if (message_length != length - cursor) return -1;
    var message: [MAX_MESSAGE_LENGTH]u8 = undefined;
    for (0..message_length) |index| {
        const value = values[cursor + index];
        if (value < 0 or value > 127) return -1;
        message[index] = @intCast(value);
    }

    var current: [MAX_OUTPUT_LENGTH]u8 = undefined;
    var filtered: [MAX_MESSAGE_LENGTH]u8 = undefined;
    var next: [MAX_OUTPUT_LENGTH]u8 = undefined;
    var current_length = normalize(message[0..message_length], filtered[0..]);
    if (current_length < longest_key) return -1;
    @memcpy(current[0..current_length], filtered[0..current_length]);
    for (0..key_count) |pass| {
        const key_index = if (mode == 0) pass else key_count - 1 - pass;
        const filtered_length = normalize(current[0..current_length], filtered[0..]);
        const key = keys[key_index][0..key_lengths[key_index]];
        const next_length = if (mode == 0)
            encryptRound(filtered[0..filtered_length], key, next[0..])
        else
            decryptRound(filtered[0..filtered_length], key, next[0..]);
        @memcpy(current[0..next_length], next[0..next_length]);
        current_length = next_length;
    }
    return hashOutput(current[0..current_length]);
}

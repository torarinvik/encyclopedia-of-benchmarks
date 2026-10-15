const MAX_PLAINTEXT: usize = 256;
const MAX_CIPHERTEXT: usize = 512;
const MAX_KEY: usize = 16;
const MAX_ROWS: usize = 512;
const LABELS = "ADFGVX";
const SQUARE = "NA1C3H8TB2OME5WRPD4F6G7I9J0KLQSUVXYZ";

fn polybiusCell(value: u8) i32 {
    for (0..36) |cell| {
        if (SQUARE[cell] == value) return @intCast(cell);
    }
    return -1;
}

fn labelIndex(value: u8) i32 {
    for (0..6) |index| {
        if (LABELS[index] == value) return @intCast(index);
    }
    return -1;
}

export fn adfgvxcipher(input: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length < 3) return -1;
    const mode = input[0];
    const text_length_value = input[1];
    const key_length_value = input[2];
    if ((mode != 0 and mode != 1) or text_length_value < 0 or key_length_value < 1 or
        key_length_value > @as(i64, @intCast(MAX_KEY))) return -1;
    const text_length: usize = @intCast(text_length_value);
    const key_length: usize = @intCast(key_length_value);
    if ((mode == 0 and text_length > MAX_PLAINTEXT) or (mode == 1 and text_length > MAX_CIPHERTEXT) or
        length != 3 + text_length + key_length) return -1;
    for (0..text_length) |index| {
        const value = input[3 + index];
        if (value < 0 or value > 127) return -1;
        if (mode == 1 and labelIndex(@intCast(value)) < 0) return -1;
    }
    if (mode == 1 and text_length % 2 != 0) return -1;
    const key_start = 3 + text_length;
    for (0..key_length) |index| {
        const value = input[key_start + index];
        if (value < 'A' or value > 'Z') return -1;
        for (0..index) |previous| {
            if (value == input[key_start + previous]) return -1;
        }
    }
    var order: [MAX_KEY]usize = undefined;
    for (0..key_length) |index| order[index] = index;
    for (1..key_length) |index| {
        const current = order[index];
        var position = index;
        while (position > 0 and input[key_start + order[position - 1]] > input[key_start + current]) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = current;
    }

    var result: [MAX_CIPHERTEXT]u8 = undefined;
    var result_length: usize = 0;
    if (mode == 0) {
        var fractionated: [MAX_CIPHERTEXT]u8 = undefined;
        var fractionated_length: usize = 0;
        for (0..text_length) |index| {
            var value: u8 = @intCast(input[3 + index]);
            if (value >= 'a' and value <= 'z') value -= 32;
            if (!((value >= 'A' and value <= 'Z') or (value >= '0' and value <= '9'))) continue;
            const cell = polybiusCell(value);
            if (cell < 0) return -1;
            fractionated[fractionated_length] = LABELS[@intCast(@divTrunc(cell, 6))];
            fractionated[fractionated_length + 1] = LABELS[@intCast(@mod(cell, 6))];
            fractionated_length += 2;
        }
        const rows = (fractionated_length + key_length - 1) / key_length;
        var table: [MAX_ROWS * MAX_KEY]u8 = undefined;
        for (0..rows) |row| {
            for (0..key_length) |column| table[row * MAX_KEY + column] = '_';
        }
        for (0..fractionated_length) |index| table[(index / key_length) * MAX_KEY + index % key_length] = fractionated[index];
        for (0..key_length) |order_index| {
            const column = order[order_index];
            for (0..rows) |row| {
                const value = table[row * MAX_KEY + column];
                if (value != '_') { result[result_length] = value; result_length += 1; }
            }
        }
    } else {
        const rows = (text_length + key_length - 1) / key_length;
        var table: [MAX_ROWS * MAX_KEY]u8 = undefined;
        var source_index: usize = 0;
        for (0..key_length) |order_index| {
            const column = order[order_index];
            for (0..rows) |row| {
                if (source_index < text_length) {
                    table[row * MAX_KEY + column] = @intCast(input[3 + source_index]);
                    source_index += 1;
                } else {
                    table[row * MAX_KEY + column] = '_';
                }
            }
        }
        var fractionated: [MAX_CIPHERTEXT]u8 = undefined;
        var fractionated_length: usize = 0;
        for (0..rows) |row| {
            for (0..key_length) |column| {
                const value = table[row * MAX_KEY + column];
                if (value != '_') { fractionated[fractionated_length] = value; fractionated_length += 1; }
            }
        }
        var index: usize = 0;
        while (index < fractionated_length) : (index += 2) {
            const row = labelIndex(fractionated[index]);
            const column = labelIndex(fractionated[index + 1]);
            if (row < 0 or column < 0) return -1;
            result[result_length] = SQUARE[@intCast(row * 6 + column)];
            result_length += 1;
        }
    }
    if (output_capacity < result_length) return -2;
    @memcpy(output[0..result_length], result[0..result_length]);
    return @intCast(result_length);
}

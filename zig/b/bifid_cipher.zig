/// Fixed-square Bifid fractionation over one complete message block.
fn letter_index(value: i64, merge_j: bool) i64 {
    var normalized = value;
    if (normalized >= 97 and normalized <= 122) normalized -= 32;
    if (normalized < 65 or normalized > 90) return -1;
    var index = normalized - 65;
    if (index == 9) {
        if (!merge_j) return -1;
        index = 8;
    } else if (index > 9) {
        index -= 1;
    }
    return index;
}

fn letter_for_index(index: usize) u8 {
    return @intCast(97 + index + @as(usize, @intFromBool(index >= 9)));
}

export fn bifid_cipher(input: [*c]const i64, length: usize,
                       output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > 258) return -1;
    const mode = input[0];
    const text_length_value = input[1];
    if ((mode != 0 and mode != 1) or text_length_value < 0 or text_length_value > 256) return -1;
    const text_length: usize = @intCast(text_length_value);
    if (length != text_length + 2) return -1;

    var rows: [256]u8 = undefined;
    var columns: [256]u8 = undefined;
    var coordinates: [512]u8 = undefined;
    var result: [256]u8 = undefined;
    var result_length: usize = 0;

    if (mode == 0) {
        for (0..text_length) |i| {
            const value = input[i + 2];
            if (value == 32) continue;
            const index_value = letter_index(value, true);
            if (index_value < 0) return -1;
            const index: usize = @intCast(index_value);
            rows[result_length] = @intCast(index / 5 + 1);
            columns[result_length] = @intCast(index % 5 + 1);
            result_length += 1;
        }
        for (0..result_length) |i| {
            coordinates[i] = rows[i];
            coordinates[result_length + i] = columns[i];
        }
        for (0..result_length) |i| {
            const row: usize = @intCast(coordinates[2 * i] - 1);
            const column: usize = @intCast(coordinates[2 * i + 1] - 1);
            result[i] = letter_for_index(row * 5 + column);
        }
    } else {
        result_length = text_length;
        for (0..text_length) |i| {
            const index_value = letter_index(input[i + 2], false);
            if (index_value < 0) return -1;
            const index: usize = @intCast(index_value);
            coordinates[2 * i] = @intCast(index / 5 + 1);
            coordinates[2 * i + 1] = @intCast(index % 5 + 1);
        }
        for (0..result_length) |i| {
            const row: usize = @intCast(coordinates[i] - 1);
            const column: usize = @intCast(coordinates[result_length + i] - 1);
            result[i] = letter_for_index(row * 5 + column);
        }
    }

    if (output_capacity < result_length or (result_length != 0 and output == null)) return -2;
    for (0..result_length) |i| output[i] = result[i];
    return @intCast(result_length);
}

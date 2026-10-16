const max_text: usize = 256;
const max_key: usize = 32;

pub export fn columnar_transposition(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3) return -1;
    const operation = input[0];
    const text_value = input[1];
    const raw_key_value = input[2];
    if ((operation != 0 and operation != 1) or text_value < 0 or text_value > max_text or
        raw_key_value < 1 or raw_key_value > max_key) return -1;
    const text_length: usize = @intCast(text_value);
    const raw_key_length: usize = @intCast(raw_key_value);
    if (length != 3 + text_length + raw_key_length) return -1;
    var key: [max_key]u8 = undefined;
    var order: [max_key]usize = undefined;
    var key_length: usize = 0;
    for (0..text_length) |index| if (input[3 + index] < 0 or input[3 + index] > 127) { return -1; };
    for (0..raw_key_length) |index| {
        const value = input[3 + text_length + index];
        if (value < 0 or value > 127) return -1;
        if (value >= 65 and value <= 90) {
            key[key_length] = @intCast(value);
            key_length += 1;
        } else if (value >= 97 and value <= 122) {
            key[key_length] = @intCast(value - 32);
            key_length += 1;
        }
    }
    if (key_length == 0) return -1;
    for (0..key_length) |index| {
        order[index] = index;
        var position = index;
        while (position > 0 and key[order[position - 1]] > key[index]) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = index;
    }
    if (text_length == 0) return 0;
    if (output == null or capacity < text_length) return -2;
    const rows = (text_length + key_length - 1) / key_length;
    if (operation == 0) {
        var written: usize = 0;
        for (0..key_length) |rank| {
            const column = order[rank];
            for (0..rows) |row| {
                const index = row * key_length + column;
                if (index < text_length) {
                    output[written] = @intCast(input[3 + index]);
                    written += 1;
                }
            }
        }
        return @intCast(written);
    }
    var column_data: [max_key * max_text]u8 = undefined;
    var column_lengths: [max_key]usize = undefined;
    var offset: usize = 0;
    const short_columns = text_length % key_length;
    for (0..key_length) |column|
        column_lengths[column] = if (short_columns == 0 or column < short_columns) rows else rows - 1;
    for (0..key_length) |rank| {
        const column = order[rank];
        for (0..column_lengths[column]) |row| {
            column_data[column * max_text + row] = @intCast(input[3 + offset]);
            offset += 1;
        }
    }
    var written: usize = 0;
    for (0..rows) |row| {
        for (0..key_length) |column| {
            if (row < column_lengths[column]) {
                output[written] = column_data[column * max_text + row];
                written += 1;
            }
        }
    }
    return @intCast(written);
}

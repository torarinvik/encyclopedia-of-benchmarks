/// ASCII case-insensitive Burrows-Wheeler transform over packed bytes.
const max_length = 256;

fn foldAscii(value: i64) u8 {
    const byte: u8 = @intCast(value);
    return if (byte >= 'A' and byte <= 'Z') byte + ('a' - 'A') else byte;
}

fn rotationLess(values: [*]const i64, n: usize, left: usize, right: usize) bool {
    for (0..n) |offset| {
        const a = foldAscii(values[1 + (left + offset) % n]);
        const b = foldAscii(values[1 + (right + offset) % n]);
        if (a != b) return a < b;
    }
    return left < right;
}

fn rotationEqualsInput(values: [*]const i64, n: usize, start: usize) bool {
    for (0..n) |offset|
        if (values[1 + (start + offset) % n] != values[1 + offset]) return false;
    return true;
}

export fn burrows_wheeler_transform_case_insensitive(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or values[0] < 0 or values[0] > max_length) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 1) return -1;
    for (1..length) |i| if (values[i] < 0 or values[i] > 127) return -1;
    const output_length = n + 4;
    if (output_capacity < output_length) return -2;

    var order: [max_length]usize = undefined;
    for (0..n) |i| order[i] = i;
    for (1..n) |i| {
        const key = order[i];
        var position = i;
        while (position > 0 and rotationLess(values, n, key, order[position - 1])) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = key;
    }

    var primary_index: usize = 0;
    for (0..n) |row|
        if (rotationEqualsInput(values, n, order[row])) { primary_index = row; };
    const encoded_index: u32 = @intCast(primary_index);
    for (0..4) |byte| output[byte] = @intCast((encoded_index >> @intCast(8 * byte)) & 0xff);
    for (0..n) |row|
        output[4 + row] = @intCast(values[1 + (order[row] + n - 1) % n]);
    return @intCast(output_length);
}

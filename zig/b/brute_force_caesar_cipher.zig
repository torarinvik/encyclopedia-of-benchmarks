const MAX_MESSAGE_LENGTH: usize = 64;
const KEY_COUNT: usize = 26;

export fn brute_force_caesar_cipher(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (length > MAX_MESSAGE_LENGTH or (length > 0 and input == null)) return -1;
    for (0..length) |i| if (input[i] < 0 or input[i] > 127) return -1;
    const needed = length * KEY_COUNT + (KEY_COUNT - 1);
    if (output == null or capacity < needed) return -2;
    var position: usize = 0;
    for (0..KEY_COUNT) |key| {
        for (0..length) |i| {
            var value = input[i];
            if (value >= 65 and value <= 90) value = 65 + (value - 65 + 26 - @as(i64, @intCast(key))) % 26;
            output[position] = @intCast(value);
            position += 1;
        }
        if (key + 1 < KEY_COUNT) { output[position] = 10; position += 1; }
    }
    return @intCast(KEY_COUNT);
}

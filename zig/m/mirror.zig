const MAX_LENGTH: usize = 256;
const MAX_INPUT_LENGTH: usize = MAX_LENGTH + 1;

export fn mirror(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > MAX_LENGTH) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 1) return -1;
    for (values[1..]) |byte| { if (byte < 1 or byte > 127) return -1; }
    if (output == null or capacity < n + 1) return -2;
    var buffer: [MAX_INPUT_LENGTH]u8 = undefined;
    for (0..n) |i| buffer[i] = @intCast(values[i + 1]);
    buffer[n] = 0;
    var logical_length: usize = 0;
    while (buffer[logical_length] != 0) : (logical_length += 1) {}
    if (logical_length > 0) {
        var left: usize = 0;
        var right: usize = logical_length - 1;
        while (left <= right) {
            const temporary = buffer[left];
            buffer[left] = buffer[right];
            buffer[right] = temporary;
            left += 1;
            if (right == 0) break;
            right -= 1;
        }
    }
    const result = output.?[0..capacity];
    @memcpy(result[0..n], buffer[0..n]);
    result[n] = 0;
    return @intCast(n);
}

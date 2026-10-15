fn edgeSpace(value: i64) bool { return (value >= 9 and value <= 13) or value == 32; }
fn digit(value: i64) i64 {
    if (value >= 65 and value <= 90) return value - 65;
    if (value >= 97 and value <= 122) return value - 97 + 26;
    if (value >= 48 and value <= 57) return value - 48 + 52;
    if (value == 43) return 62;
    if (value == 47) return 63;
    return -1;
}

pub export fn base64_to_binary(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or input[0] < 0 or input[0] > 256) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| if (input[i + 1] < 0 or input[i + 1] > 127) return -1;
    var begin: usize = 0;
    var end: usize = n;
    while (begin < end and edgeSpace(input[1 + begin])) : (begin += 1) {}
    while (end > begin and edgeSpace(input[end])) : (end -= 1) {}
    if (begin == end) return -1;
    const negative = input[1 + begin] == 45;
    if (negative) begin += 1;
    for (begin..end) |i| if (digit(input[1 + i]) < 0) return -1;
    const output_length = (end - begin) * 6 + @as(usize, if (negative) 1 else 0);
    if (capacity < output_length or output == null) return -2;
    var offset: usize = 0;
    if (negative) { output[offset] = '-'; offset += 1; }
    for (begin..end) |i| {
        const value: u8 = @intCast(digit(input[1 + i]));
        for (0..6) |bit| {
            output[offset] = '0' + ((value >> @intCast(5 - bit)) & 1);
            offset += 1;
        }
    }
    return @intCast(output_length);
}

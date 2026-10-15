const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
fn edgeSpace(value: i64) bool { return (value >= 9 and value <= 13) or value == 32; }

pub export fn binary_to_base64(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or input[0] < 1 or input[0] > 256) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| if (input[1 + i] < 0 or input[1 + i] > 127) return -1;
    var begin: usize = 0;
    var end: usize = n;
    while (begin < end and edgeSpace(input[1 + begin])) : (begin += 1) {}
    while (end > begin and edgeSpace(input[end])) : (end -= 1) {}
    if (begin == end) return -1;
    const negative = input[1 + begin] == '-';
    if (negative) begin += 1;
    for (begin..end) |i| if (input[1 + i] != '0' and input[1 + i] != '1') return -1;
    const bit_count = end - begin;
    const padding = 6 - bit_count % 6;
    const groups = (bit_count + padding) / 6;
    const output_length = groups + @as(usize, if (negative) 1 else 0);
    if (capacity < output_length or output == null) return -2;
    var offset: usize = 0;
    if (negative) { output[offset] = '-'; offset += 1; }
    for (0..groups) |group| {
        var value: usize = 0;
        for (0..6) |bit| {
            value <<= 1;
            const position = group * 6 + bit;
            if (position >= padding and input[1 + begin + position - padding] == '1') value += 1;
        }
        output[offset] = alphabet[value];
        offset += 1;
    }
    return @intCast(output_length);
}

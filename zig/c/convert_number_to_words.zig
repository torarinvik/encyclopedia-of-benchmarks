const words = [_][]const u8{"zero","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen","twenty","thirty","forty","fifty","sixty","seventy","eighty","ninety","quadrillion","trillion","billion","million","thousand","hundred","billiard","milliard","crore crore","lakh crore","crore","lakh","negative"};
fn appendWord(output: [*]u8, length: usize, id: usize, separate: bool) usize {
    var position = length;
    if (separate and position > 0) { output[position] = ' '; position += 1; }
    for (words[id], 0..) |byte, i| output[position + i] = byte;
    return position + words[id].len;
}
fn appendSmall(n: u64, output: [*]u8, length: usize) usize {
    if (n < 10) return appendWord(output, length, @intCast(n), true);
    if (n < 20) return appendWord(output, length, @intCast(n + 10), true);
    var position = appendWord(output, length, @intCast(n / 10 + 18), true);
    if (n % 10 != 0) { output[position] = '-'; position += 1; position = appendWord(output, position, @intCast(n % 10), false); }
    return position;
}
fn scaleCount(system: usize) usize { return if (system == 1) 5 else 6; }
fn scalePower(system: usize, index: usize) u64 {
    if (system == 0) return [_]u64{1_000_000_000_000_000,1_000_000_000_000,1_000_000_000,1_000_000,1_000,100}[index];
    if (system == 1) return [_]u64{1_000_000_000_000_000,1_000_000_000,1_000_000,1_000,100}[index];
    return [_]u64{100_000_000_000_000,1_000_000_000_000,10_000_000,100_000,1_000,100}[index];
}
fn scaleWord(system: usize, index: usize) usize {
    if (system == 0) return [_]usize{28,29,30,31,32,33}[index];
    if (system == 1) return [_]usize{34,35,31,32,33}[index];
    return [_]usize{36,37,38,39,32,33}[index];
}
fn appendNumber(n_input: u64, system: usize, output: [*]u8, length: usize, depth: usize) usize {
    if (depth > 8) return length;
    var n = n_input;
    var position = length;
    for (0..scaleCount(system)) |i| {
        const power = scalePower(system, i);
        const group = n / power;
        n %= power;
        if (group == 0) continue;
        if (group >= 100) position = appendNumber(group, system, output, position, depth + 1)
        else position = appendSmall(group, output, position);
        position = appendWord(output, position, scaleWord(system, i), true);
    }
    if (n > 0 or position == length) position = appendSmall(n, output, position);
    return position;
}

pub export fn convert_number_to_words(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 2 or input[1] < 0 or input[1] > 2) return -1;
    const system: usize = @intCast(input[1]);
    const number = input[0];
    const limit: i64 = if (system == 0) 999_999_999_999_999_999 else 9_000_000_000_000_000_000;
    if (number < -limit or number > limit) return -1;
    const magnitude: u64 = @intCast(if (number < 0) -number else number);
    var temporary: [512]u8 = @splat(0);
    var count: usize = 0;
    if (number < 0) count = appendWord(&temporary, count, 40, true);
    count = appendNumber(magnitude, system, &temporary, count, 0);
    if (capacity < count or output == null) return -2;
    @memcpy(output[0..count], temporary[0..count]);
    return @intCast(count);
}

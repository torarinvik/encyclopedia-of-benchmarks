const MAX_INPUT: usize = 1024;
const MAX_ENTRIES: usize = 512;
fn ws(c: u8) bool { return (c >= 9 and c <= 13) or (c >= 28 and c <= 32); }
fn put32(out: [*]u8, pos: *usize, value: u32) void {
    var bits = value;
    for (0..4) |_| { out[pos.*] = @truncate(bits); pos.* += 1; bits >>= 8; }
}
export fn word_occurrence(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT + 1) return -1;
    const input_ptr = input.?;
    const n_arg = input_ptr[0];
    if (n_arg < 0 or n_arg > @as(i64, @intCast(MAX_INPUT)) or length != @as(usize, @intCast(n_arg + 1))) return -1;
    const n: usize = @intCast(n_arg);
    var text: [MAX_INPUT]u8 = @splat(0);
    for (0..n) |i| { const value = input_ptr[i + 1]; if (value < 0 or value > 127) return -1; text[i] = @intCast(value); }
    var starts: [MAX_ENTRIES]usize = @splat(0);
    var lens: [MAX_ENTRIES]usize = @splat(0);
    var counts: [MAX_ENTRIES]u32 = @splat(0);
    var entries: usize = 0;
    var i: usize = 0;
    while (i < n) {
        while (i < n and ws(text[i])) : (i += 1) {}
        if (i == n) break;
        const start = i;
        while (i < n and !ws(text[i])) : (i += 1) {}
        const token_len = i - start;
        var entry: usize = 0;
        while (entry < entries) {
            if (lens[entry] == token_len) {
                var offset: usize = 0;
                while (offset < token_len and text[starts[entry] + offset] == text[start + offset]) : (offset += 1) {}
                if (offset == token_len) break;
            }
            entry += 1;
        }
        if (entry == entries) {
            if (entries >= MAX_ENTRIES) return -1;
            starts[entry] = start;
            lens[entry] = token_len;
            entries += 1;
        }
        counts[entry] += 1;
    }
    var need: usize = 4;
    for (0..entries) |j| need += 8 + lens[j];
    if (output == null or capacity < need) return -2;
    const output_ptr = output.?;
    var pos: usize = 0;
    put32(output_ptr, &pos, @intCast(entries));
    for (0..entries) |j| {
        put32(output_ptr, &pos, @intCast(lens[j]));
        for (0..lens[j]) |q| { output_ptr[pos] = text[starts[j] + q]; pos += 1; }
        put32(output_ptr, &pos, counts[j]);
    }
    return @intCast(pos);
}

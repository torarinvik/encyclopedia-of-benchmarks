const max_input_length: usize = 4096;
fn lower(c: u8) u8 { return if (c >= 'A' and c <= 'Z') c + 32 else c; }
fn vowel(c: u8) bool { return c == 'a' or c == 'e' or c == 'i' or c == 'o' or c == 'u'; }

export fn remove_vowels(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 1 or length > max_input_length + 1) return -1;
    if (values[0] < 0 or values[0] > max_input_length) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 1) return -1;
    var result: usize = 0;
    for (0..n) |i| { if (values[i+1] < 0 or values[i+1] > 127) return -1; if (!vowel(lower(@intCast(values[i+1])))) result += 1; }
    if (result > capacity or (result > 0 and output == null)) return -2;
    var written: usize = 0;
    for (0..n) |i| { const c: u8 = lower(@intCast(values[i+1])); if (!vowel(c)) { output[written] = c; written += 1; } }
    return @intCast(written);
}

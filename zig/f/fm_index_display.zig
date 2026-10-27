const MaxText: usize = 32;
const MaxInput: usize = 36;
const Alphabet: usize = 5;

fn suffixLess(text: *const [MaxText + 1]i64, size: usize, a0: usize, b0: usize) bool {
    var a = a0;
    var b = b0;
    while (a < size and b < size) {
        if (text[a] != text[b]) return text[a] < text[b];
        a += 1;
        b += 1;
    }
    return a == size and b != size;
}

export fn fm_index_display(input_opt: ?[*]const i64, length: usize,
                           output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > MaxInput) return -1;
    const input = input_opt.?;
    const n0 = input[0];
    if (n0 < 1 or n0 > @as(i64, @intCast(MaxText)) or length != @as(usize, @intCast(n0)) + 4) return -1;
    const n: usize = @intCast(n0);
    const left0 = input[n + 1];
    const right0 = input[n + 2];
    const stride0 = input[n + 3];
    if (left0 < 0 or right0 < left0 or right0 >= n0 or stride0 < 1 or stride0 > n0) return -1;
    const left: usize = @intCast(left0);
    const right: usize = @intCast(right0);
    const stride: usize = @intCast(stride0);
    const size = n + 1;
    var text: [MaxText + 1]i64 = @splat(0);
    for (0..n) |i| {
        if (input[i + 1] < 1 or input[i + 1] > 4) return -1;
        text[i] = input[i + 1];
    }
    text[n] = 0;
    var sa: [MaxText + 1]usize = undefined;
    for (0..size) |i| sa[i] = i;
    for (1..size) |i| {
        const key = sa[i];
        var j = i;
        while (j > 0 and suffixLess(&text, size, key, sa[j - 1])) {
            sa[j] = sa[j - 1];
            j -= 1;
        }
        sa[j] = key;
    }
    var isa: [MaxText + 1]usize = undefined;
    var bwt: [MaxText + 1]usize = undefined;
    var freq: [Alphabet]usize = @splat(0);
    for (0..size) |row| {
        const pos = sa[row];
        isa[pos] = row;
        bwt[row] = @intCast(text[(pos + size - 1) % size]);
        freq[bwt[row]] += 1;
    }
    var first: [Alphabet]usize = @splat(0);
    var total: usize = 0;
    for (0..Alphabet) |symbol| { first[symbol] = total; total += freq[symbol]; }
    var seen: [Alphabet]usize = @splat(0);
    var lf: [MaxText + 1]usize = undefined;
    for (0..size) |row| {
        const symbol = bwt[row];
        lf[row] = first[symbol] + seen[symbol];
        seen[symbol] += 1;
    }
    var sampled_isa: [MaxText + 1]usize = undefined;
    var sampled: [MaxText + 1]bool = @splat(false);
    var pos: usize = 0;
    while (pos < n) : (pos += 1) { if ((pos + 1) % stride == 0) { sampled[pos] = true; sampled_isa[pos] = isa[pos]; } }
    sampled[n] = true;
    sampled_isa[n] = isa[n];
    var sample = ((right + 1) / stride + 1) * stride - 1;
    if (sample > n) sample = n;
    if (!sampled[sample]) return -1;
    var row = sampled_isa[sample];
    var current = sample;
    while (current > right + 1) { row = lf[row]; current -= 1; }
    var reversed: [MaxText]u8 = @splat(0);
    var count: usize = 0;
    while (current > left) {
        reversed[count] = @intCast(bwt[row]);
        count += 1;
        row = lf[row];
        current -= 1;
    }
    if (count != right - left + 1) return -1;
    if (output_opt == null or capacity < count) return -2;
    for (0..count) |i| output_opt.?[i] = reversed[count - 1 - i];
    return @intCast(count);
}

/// Clean-room bounded pcompress2 compression pipeline.
const max_length = 32;
const max_output = 8 + max_length * 16;
const symbols = 257;

const BitWriter = struct {
    bytes: [*]u8,
    length: usize = 0,
    buffer: u8 = 0,
    bits_to_go: i32 = 8,
};

fn rotationLess(input: [*]const u8, n: usize, left: usize, right: usize) bool {
    for (0..n) |offset| {
        const a = input[(left + offset) % n];
        const b = input[(right + offset) % n];
        if (a != b) return a < b;
    }
    return left < right;
}

fn outputBit(w: *BitWriter, bit: bool) void {
    w.buffer >>= 1;
    if (bit) w.buffer |= 0x80;
    w.bits_to_go -= 1;
    if (w.bits_to_go == 0) { w.bytes[w.length] = w.buffer; w.length += 1; w.bits_to_go = 8; }
}
fn bitPlusFollow(w: *BitWriter, bit: bool, follow: *i32) void {
    outputBit(w, bit);
    while (follow.* > 0) { outputBit(w, !bit); follow.* -= 1; }
}
fn encodeSymbol(symbol: usize, cum: *const [258]i32, low: *u32, high: *u32,
                follow: *i32, w: *BitWriter) void {
    const span: u64 = @as(u64, high.* - low.*) + 1;
    const old_low = low.*;
    high.* = old_low + @as(u32, @intCast(span * @as(u64, @intCast(cum[symbol - 1])) / @as(u64, @intCast(cum[0])))) - 1;
    low.* = old_low + @as(u32, @intCast(span * @as(u64, @intCast(cum[symbol])) / @as(u64, @intCast(cum[0]))));
    while (true) {
        if (high.* < 32768) bitPlusFollow(w, false, follow)
        else if (low.* >= 32768) { bitPlusFollow(w, true, follow); low.* -= 32768; high.* -= 32768; }
        else if (low.* >= 16384 and high.* < 49152) { follow.* += 1; low.* -= 16384; high.* -= 16384; }
        else break;
        low.* *= 2;
        high.* = high.* * 2 + 1;
    }
}
fn updateModel(symbol: usize, char_to_index: *[256]usize, index_to_char: *[258]u8,
               freq: *[258]i32, cum: *[258]i32) void {
    if (cum[0] == 16383) {
        var total: i32 = 0;
        var i: i32 = symbols;
        while (i >= 0) : (i -= 1) {
            const index: usize = @intCast(i);
            freq[index] = @divTrunc(freq[index] + 1, 2);
            cum[index] = total;
            total += freq[index];
        }
    }
    var i = symbol;
    while (freq[i] == freq[i - 1]) i -= 1;
    if (i < symbol) {
        const a = index_to_char[i]; const b = index_to_char[symbol];
        index_to_char[i] = b; index_to_char[symbol] = a;
        char_to_index[a] = symbol; char_to_index[b] = i;
    }
    freq[i] += 1;
    var j = i;
    while (j > 0) { j -= 1; cum[j] += 1; }
}
fn arithmeticEncode(data: [*]const u8, count: usize, encoded: [*]u8) usize {
    var char_to_index: [256]usize = undefined;
    var index_to_char: [258]u8 = [_]u8{0} ** 258;
    var freq: [258]i32 = undefined;
    var cum: [258]i32 = undefined;
    for (0..256) |i| { char_to_index[i] = i + 1; index_to_char[i + 1] = @intCast(i); }
    for (0..258) |i| { freq[i] = 1; cum[i] = symbols - @as(i32, @intCast(i)); }
    freq[0] = 0;
    var writer = BitWriter{ .bytes = encoded };
    var low: u32 = 0; var high: u32 = 65535; var follow: i32 = 0;
    for (0..count) |i| {
        const symbol = char_to_index[data[i]];
        encodeSymbol(symbol, &cum, &low, &high, &follow, &writer);
        updateModel(symbol, &char_to_index, &index_to_char, &freq, &cum);
    }
    encodeSymbol(257, &cum, &low, &high, &follow, &writer);
    follow += 1;
    bitPlusFollow(&writer, low >= 16384, &follow);
    writer.bytes[writer.length] = writer.buffer >> @as(u5, @intCast(writer.bits_to_go));
    writer.length += 1;
    return writer.length;
}
fn compressBounded(input: [*]const u8, n: usize, output: [*]u8) usize {
    var order: [max_length]usize = undefined;
    var last: [max_length]u8 = undefined;
    var rle: [max_length * 2]u8 = undefined;
    var rle_length: usize = 0;
    for (0..n) |i| order[i] = i;
    for (1..n) |i| {
        const key = order[i]; var j = i;
        while (j > 0 and rotationLess(input, n, key, order[j - 1])) { order[j] = order[j - 1]; j -= 1; }
        order[j] = key;
    }
    var primary: usize = 0;
    for (0..n) |row| { if (order[row] == 0) primary = row; last[row] = input[(order[row] + n - 1) % n]; }
    var i: usize = 0;
    while (i < n) {
        var count: usize = 1; const value = last[i];
        while (i + count < n and last[i + count] == value and count < 127) count += 1;
        if (count == 1) {
            while (i + count < n and last[i + count - 1] != last[i + count] and
                   (i + count + 1 == n or last[i + count] != last[i + count + 1])) count += 1;
            rle[rle_length] = @intCast(count & 0x7f); rle_length += 1;
            for (0..count) |j| { rle[rle_length] = last[i + j]; rle_length += 1; }
            i += count;
        } else { rle[rle_length] = @intCast(count | 0x80); rle_length += 1; rle[rle_length] = value; rle_length += 1; i += count; }
    }
    output[0] = @intCast(n); output[1] = 0; output[2] = 0; output[3] = 0;
    output[4] = @intCast(primary); output[5] = 0; output[6] = 0; output[7] = 0;
    return 8 + arithmeticEncode(&rle, rle_length, output + 8);
}

export fn pcompress2(values: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    const input_values = values orelse return -1;
    if (length < 2 or input_values[0] < 1 or input_values[0] > @as(i64, max_length)) return -1;
    const n: usize = @intCast(input_values[0]);
    if (length != n + 1) return -1;
    var input: [max_length]u8 = undefined;
    for (0..n) |i| { if (input_values[i + 1] < 0 or input_values[i + 1] > 255) return -1; input[i] = @intCast(input_values[i + 1]); }
    var encoded: [max_output]u8 = undefined;
    const encoded_length = compressBounded(&input, n, &encoded);
    if (output_capacity < encoded_length) return -2;
    const out = output orelse return -2;
    for (0..encoded_length) |i| out[i] = encoded[i];
    return @intCast(encoded_length);
}

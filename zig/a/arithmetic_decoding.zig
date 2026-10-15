/// Decode an exact arithmetic-coded lower-bound numerator.
export fn arithmetic_decoding(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 5) return -1;
    const count = input[0];
    const alphabet_size = input[1];
    if (count < 1 or count > 12 or alphabet_size < 1 or alphabet_size > count
        or length != @as(usize, @intCast(3 + 2 * alphabet_size))) return -1;

    var denominator: i64 = 1;
    for (0..@intCast(count)) |_| denominator *= count;
    const code = input[2];
    if (code < 0 or code >= denominator) return -1;

    var symbols: [12]i64 = @splat(0);
    var cumulative: [13]i64 = @splat(0);
    var total: i64 = 0;
    for (0..@intCast(alphabet_size)) |index| {
        const symbol = input[3 + 2 * index];
        const frequency = input[4 + 2 * index];
        if (symbol < 0 or symbol > 255 or frequency < 1 or frequency > count
            or (index > 0 and symbol <= symbols[index - 1])) return -1;
        symbols[index] = symbol;
        total += frequency;
        cumulative[index + 1] = total;
    }
    if (total != count) return -1;
    if (capacity < @as(usize, @intCast(count)) or output == null) return -2;

    var low: i64 = 0;
    var high: i64 = 1;
    var scale = @divExact(denominator, count);
    for (0..@intCast(count)) |step| {
        const range = high - low;
        const base = low * count;
        var found = false;
        for (0..@intCast(alphabet_size)) |index| {
            const symbol_low = base + range * cumulative[index];
            const symbol_high = base + range * cumulative[index + 1];
            if (code >= symbol_low * scale and code < symbol_high * scale) {
                output[step] = @intCast(symbols[index]);
                low = symbol_low;
                high = symbol_high;
                found = true;
                break;
            }
        }
        if (!found) return -1;
        if (step + 1 < @as(usize, @intCast(count))) scale = @divExact(scale, count);
    }
    return count;
}

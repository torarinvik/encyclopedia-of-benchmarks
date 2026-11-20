const MAX_COUNT: usize = 32;
const MAX_WORDS: usize = 66;

fn positiveUnits(code: u8) u64 {
    var cursor: i32 = 6;
    const regime_bit = (code >> 6) & 1;
    var run: i32 = 0;
    while (cursor >= 0 and ((code >> @as(u5, @intCast(cursor))) & 1) == regime_bit) {
        run += 1;
        cursor -= 1;
    }
    const regime = if (regime_bit != 0) run - 1 else -run;
    if (cursor >= 0) cursor -= 1;
    var exponent: i32 = 0;
    for (0..2) |_| {
        exponent <<= 1;
        if (cursor >= 0) {
            exponent |= @as(i32, (code >> @as(u5, @intCast(cursor))) & 1);
            cursor -= 1;
        }
    }
    const width: u32 = @intCast(cursor + 1);
    const fraction: u64 = if (width == 0) 0 else @as(u64, @as(u16, code) & ((@as(u16, 1) << @as(u4, @intCast(width))) - 1));
    const significand = (@as(u64, 1) << @as(u6, @intCast(width))) + fraction;
    const shift: u6 = @intCast(4 * regime + exponent + 24 - @as(i32, @intCast(width)));
    return significand << shift;
}

fn compareRatioToUnit(scaled: u64, denominator: u64, unit: u64) i32 {
    const quotient = scaled / denominator;
    const remainder = scaled % denominator;
    if (quotient < unit) return -1;
    if (quotient > unit) return 1;
    return if (remainder == 0) 0 else 1;
}

fn encodeOne(numerator: i64, denominator: i64) u8 {
    if (numerator == 0) return 0;
    const negative = numerator < 0;
    const magnitude: u64 = @intCast(if (negative) -numerator else numerator);
    const scaled = magnitude << 24;
    var chosen: u8 = undefined;
    if (compareRatioToUnit(scaled, @as(u64, @intCast(denominator)), 1) <= 0) {
        chosen = 1;
    } else if (compareRatioToUnit(scaled, @as(u64, @intCast(denominator)), positiveUnits(127)) >= 0) {
        chosen = 127;
    } else {
        var low: i32 = 1;
        var high: i32 = 127;
        while (low < high) {
            const middle = low + @divTrunc(high - low, 2);
            if (compareRatioToUnit(scaled, @as(u64, @intCast(denominator)), positiveUnits(@intCast(middle))) > 0) low = middle + 1 else high = middle;
        }
        const upper: u8 = @intCast(low);
        const lower = upper - 1;
        const midpoint = positiveUnits(lower) + positiveUnits(upper);
        const midpoint_comparison = compareRatioToUnit(scaled << 1, @as(u64, @intCast(denominator)), midpoint);
        chosen = if (midpoint_comparison < 0) lower else if (midpoint_comparison > 0) upper else if ((lower & 1) == 0) lower else upper;
    }
    return if (negative) 0 -% chosen else chosen;
}

pub export fn posit8_rational_encoder(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (length < 1 or length > MAX_WORDS) return -1;
    const raw_count = values[0];
    if (raw_count < 0 or raw_count > @as(i64, @intCast(MAX_COUNT)) or length != 1 + @as(usize, @intCast(raw_count)) * 2) return -1;
    const count: usize = @intCast(raw_count);
    for (0..count) |index| {
        const numerator = values[1 + 2 * index];
        const denominator = values[2 + 2 * index];
        if (numerator < -2147483648 or numerator > 2147483648 or denominator < 1 or denominator > 2147483648) return -1;
    }
    const dest = output orelse return -2;
    if (capacity < count) return -2;
    var staged = [_]u8{0} ** MAX_COUNT;
    for (0..count) |index| staged[index] = encodeOne(values[1 + 2 * index], values[2 + 2 * index]);
    for (0..count) |index| dest[index] = staged[index];
    return @intCast(count);
}

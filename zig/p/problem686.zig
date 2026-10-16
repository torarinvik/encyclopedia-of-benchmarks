/// Find the nth power of two whose decimal prefix is 123.
const MAX_POSITION: i64 = 678_910;
const LOG10_2: f64 = 0.30102999566398114;
const LOWER_LIMIT: f64 = 0.08990511143939792;
const UPPER_LIMIT: f64 = 0.09342168516223506;
const ROUND_SCALE: f64 = 1_000_000_000_000_000.0;

fn roundedDecimalPart(exponent: i64) f64 {
    const logarithm = LOG10_2 * @as(f64, @floatFromInt(exponent));
    const integer_part: i64 = @intFromFloat(logarithm);
    const scaled = (logarithm - @as(f64, @floatFromInt(integer_part))) * ROUND_SCALE;
    var rounded: i64 = @intFromFloat(scaled);
    const remainder = scaled - @as(f64, @floatFromInt(rounded));
    if (remainder > 0.5 or (remainder == 0.5 and @rem(rounded, 2) != 0)) rounded += 1;
    return @as(f64, @floatFromInt(rounded)) / ROUND_SCALE;
}

export fn problem686(number: i64) i64 {
    if (number < 1 or number > MAX_POSITION) return -1;
    var power: i64 = 90;
    var position: i64 = 0;
    var previous: i64 = 0;
    while (position < number) {
        const difference = roundedDecimalPart(power);
        if (difference >= UPPER_LIMIT) power += 93
        else if (difference < LOWER_LIMIT) power += 196
        else { previous = power; power += 196; position += 1; }
    }
    return previous;
}

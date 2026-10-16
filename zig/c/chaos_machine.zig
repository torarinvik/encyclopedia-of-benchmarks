/// Seeded portable port of the pinned logistic-map/Xorshift machine.
fn fractionOne(value: f64) f64 { return value - @floor(value); }
fn roundTen(value: f64) f64 {
    const bits: u64 = @bitCast(value);
    const exponent = (bits >> 52) & 0x7ff;
    if (exponent == 0) return 0.0;
    const mantissa = (@as(u64, 1) << 52) | (bits & ((@as(u64, 1) << 52) - 1));
    const low_product = (mantissa & 0xffff_ffff) * 9_765_625;
    const high_product = (mantissa >> 32) * 9_765_625;
    const shifted_high = high_product << 32;
    const low = shifted_high +% low_product;
    const carry: u64 = if (low < shifted_high) 1 else 0;
    const high = (high_product >> 32) + carry;
    const shift: i32 = 1065 - @as(i32, @intCast(exponent));
    if (shift > 77) return 0.0;
    var rounded: u64 = 0;
    var relation: i32 = 0;
    if (shift < 64) {
        const shift_u: u6 = @intCast(shift);
        rounded = (high << @as(u6, @intCast(64 - shift))) | (low >> shift_u);
        const remainder = low & ((@as(u64, 1) << shift_u) - 1);
        const half = @as(u64, 1) << @as(u6, @intCast(shift - 1));
        if (remainder > half) relation = 1;
        if (remainder < half) relation = -1;
    } else if (shift == 64) {
        rounded = high;
        const half = @as(u64, 1) << 63;
        if (low > half) relation = 1;
        if (low < half) relation = -1;
    } else {
        const upper_bits: u6 = @intCast(shift - 64);
        rounded = high >> upper_bits;
        const remainder_high = high & ((@as(u64, 1) << upper_bits) - 1);
        const half_high = @as(u64, 1) << @as(u6, @intCast(shift - 65));
        if (remainder_high > half_high or (remainder_high == half_high and low != 0)) relation = 1;
        if (remainder_high < half_high) relation = -1;
    }
    if (relation > 0 or (relation == 0 and (rounded & 1) != 0)) rounded += 1;
    return @as(f64, @floatFromInt(rounded)) / 10_000_000_000.0;
}
fn pull(machine_time: *u64, buffer: *[5]f64, params: *[5]f64) u32 {
    const key: usize = @intCast(machine_time.* % 5);
    for (0..3) |_| {
        const rate = params.*[key];
        const value = buffer.*[key];
        buffer.*[key] = roundTen(rate * value * (1.0 - value));
        params.*[key] = fractionOne(@as(f64, @floatFromInt(machine_time.*)) * 0.01 + rate * 1.01) + 3.0;
    }
    var x: u64 = @intFromFloat(buffer.*[(key + 2) % 5] * 10_000_000_000.0);
    var y: u64 = @intFromFloat(buffer.*[(key + 3) % 5] * 10_000_000_000.0);
    machine_time.* += 1;
    x ^= y >> 13; y ^= x << 17; x ^= y >> 5;
    return @truncate(x & 0xFFFFFFFF);
}
export fn chaos_machine(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > 66) return -1;
    if (values[0] < 0 or values[0] > 64 or length != @as(usize, @intCast(values[0])) + 2) return -1;
    const seed_count: usize = @intCast(values[0]);
    const pull_input = values[length - 1];
    if (pull_input < 0 or pull_input > 64) return -1;
    for (0..seed_count) |index| {
        if (values[index + 1] < 0 or values[index + 1] > 1_000_000) return -1;
    }
    const pull_count: usize = @intCast(pull_input);
    const required = 4 * pull_count;
    if (required > output_capacity or (required != 0 and output == null)) return -2;
    var buffer = [5]f64{0.33, 0.44, 0.55, 0.44, 0.33};
    var params = [5]f64{0.0, 0.0, 0.0, 0.0, 0.0};
    var machine_time: u64 = 0;
    for (0..seed_count) |seed_index| {
        const seed: f64 = @floatFromInt(values[seed_index + 1]);
        for (0..5) |key| {
            if (buffer[key] == 0.0) return -1;
            const evolution = seed / buffer[key];
            const value = fractionOne(buffer[(key + 1) % 5] + evolution);
            const rate = fractionOne(params[key] + evolution) + 3.0;
            buffer[key] = roundTen(rate * value * (1.0 - value));
            params[key] = rate;
        }
        machine_time += 1;
    }
    if (required == 0) return 0;
    const out = output[0..required];
    for (0..pull_count) |index| {
        const result = pull(&machine_time, &buffer, &params);
        for (0..4) |byte| out[4 * index + byte] = @truncate(result >> @intCast(8 * byte));
    }
    return @intCast(required);
}

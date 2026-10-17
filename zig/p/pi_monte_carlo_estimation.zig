const MT_N: usize = 624;
const MT_M: usize = 397;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 3;

const Mt19937 = struct {
    state: [MT_N]u32,
    index: usize,
};

fn mtSeed(seed: u32) Mt19937 {
    var rng: Mt19937 = .{ .state = [_]u32{0} ** MT_N, .index = MT_N };
    rng.state[0] = 19_650_218;
    for (1..MT_N) |i| {
        const previous = rng.state[i - 1];
        rng.state[i] = 1_812_433_253 *% (previous ^ (previous >> 30)) +% @as(u32, @intCast(i));
    }

    var i: usize = 1;
    var key_index: usize = 0;
    for (0..MT_N) |_| {
        const previous = rng.state[i - 1];
        rng.state[i] = (rng.state[i] ^ ((previous ^ (previous >> 30)) *% 1_664_525)) +% seed +% @as(u32, @intCast(key_index));
        i += 1;
        key_index += 1;
        if (i >= MT_N) {
            rng.state[0] = rng.state[MT_N - 1];
            i = 1;
        }
        if (key_index >= 1) key_index = 0;
    }
    for (0..MT_N - 1) |_| {
        const previous = rng.state[i - 1];
        rng.state[i] = (rng.state[i] ^ ((previous ^ (previous >> 30)) *% 1_566_083_941)) -% @as(u32, @intCast(i));
        i += 1;
        if (i >= MT_N) {
            rng.state[0] = rng.state[MT_N - 1];
            i = 1;
        }
    }
    rng.state[0] = 0x8000_0000;
    return rng;
}

fn mtNextU32(rng: *Mt19937) u32 {
    if (rng.index >= MT_N) {
        for (0..MT_N - MT_M) |i| {
            const joined = (rng.state[i] & 0x8000_0000) | (rng.state[i + 1] & 0x7fff_ffff);
            const magic: u32 = if (joined & 1 != 0) 0x9908_b0df else 0;
            rng.state[i] = rng.state[i + MT_M] ^ (joined >> 1) ^ magic;
        }
        for (MT_N - MT_M..MT_N - 1) |i| {
            const joined = (rng.state[i] & 0x8000_0000) | (rng.state[i + 1] & 0x7fff_ffff);
            const magic: u32 = if (joined & 1 != 0) 0x9908_b0df else 0;
            rng.state[i] = rng.state[i - (MT_N - MT_M)] ^ (joined >> 1) ^ magic;
        }
        const joined = (rng.state[MT_N - 1] & 0x8000_0000) | (rng.state[0] & 0x7fff_ffff);
        const magic: u32 = if (joined & 1 != 0) 0x9908_b0df else 0;
        rng.state[MT_N - 1] = rng.state[MT_M - 1] ^ (joined >> 1) ^ magic;
        rng.index = 0;
    }
    var value = rng.state[rng.index];
    rng.index += 1;
    value ^= value >> 11;
    value ^= (value << 7) & 0x9d2c_5680;
    value ^= (value << 15) & 0xefc6_0000;
    value ^= value >> 18;
    return value;
}

fn mtRandom(rng: *Mt19937) f64 {
    const high = mtNextU32(rng) >> 5;
    const low = mtNextU32(rng) >> 6;
    return (@as(f64, @floatFromInt(high)) * 67_108_864.0 + @as(f64, @floatFromInt(low))) * (1.0 / 9_007_199_254_740_992.0);
}

export fn pi_monte_carlo_estimation(input: [*c]const f64, input_length: usize, output: [*c]f64, output_capacity: usize) i64 {
    @setFloatMode(.strict);
    if (input == null or input_length < 1 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input_length != 2) return -1;
    const simulations_value = input[0];
    const seed_value = input[1];
    if (!@import("std").math.isFinite(simulations_value) or !@import("std").math.isFinite(seed_value)) return -1;
    if (@trunc(simulations_value) != simulations_value or @trunc(seed_value) != seed_value) return -1;
    if (simulations_value < 1 or simulations_value > 100_000 or seed_value < 0 or seed_value > 4_294_967_295) return -1;
    if (output == null or output_capacity < 1) return -2;

    const simulations: usize = @intFromFloat(simulations_value);
    const seed: u32 = @intFromFloat(seed_value);
    var rng = mtSeed(seed);
    var hits: usize = 0;
    for (0..simulations) |_| {
        const x = mtRandom(&rng);
        const y = mtRandom(&rng);
        const x_squared = x * x;
        const y_squared = y * y;
        if (x_squared + y_squared <= 1.0) hits += 1;
    }
    output[0] = @as(f64, @floatFromInt(4 * hits)) / @as(f64, @floatFromInt(simulations));
    return 1;
}

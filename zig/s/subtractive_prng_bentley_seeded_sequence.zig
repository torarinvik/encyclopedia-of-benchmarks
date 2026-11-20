const STATE_SIZE: usize = 55;
const SHORT_LAG: usize = 24;
const WARMUP_VALUES: usize = 165;
const MODULUS: i32 = 1_000_000_000;

fn putI64Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u64 = @intCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

pub export fn subtractive_prng_bentley_seeded_sequence(
    input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize,
) i64 {
    if (input == null or length != 2) return -1;
    const seed = input[0];
    const count = input[1];
    if (seed < 0 or seed >= 1_000_000_000 or count < 0 or count > 64) return -1;
    const n: usize = @intCast(count);
    const required = n * 8;
    if (capacity < required or (required > 0 and output == null)) return -2;
    if (n == 0) return 0;

    var seed_state: [STATE_SIZE]i32 = undefined;
    var ring: [STATE_SIZE]i32 = undefined;
    seed_state[0] = @intCast(seed);
    seed_state[1] = 1;
    for (2..STATE_SIZE) |i| {
        var value = seed_state[i - 2] - seed_state[i - 1];
        if (value < 0) value += MODULUS;
        seed_state[i] = value;
    }
    for (0..STATE_SIZE) |i| ring[i] = seed_state[(34 * (i + 1)) % STATE_SIZE];

    var write_index: usize = 0;
    var lag_index: usize = STATE_SIZE - SHORT_LAG;
    for (0..WARMUP_VALUES + n) |step| {
        var value = ring[write_index] - ring[lag_index];
        if (value < 0) value += MODULUS;
        ring[write_index] = value;
        if (step >= WARMUP_VALUES)
            putI64Le(output, (step - WARMUP_VALUES) * 8, value);
        write_index = (write_index + 1) % STATE_SIZE;
        lag_index = (lag_index + 1) % STATE_SIZE;
    }
    return @intCast(required);
}

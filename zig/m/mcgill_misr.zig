const MIN_EXPERIMENTS: i64 = 1;
const MAX_EXPERIMENTS: i64 = 1_000;
const MAX_OUTPUT_BYTES: usize = 123;
const MASK_48: u64 = 0xFFFFFFFFFFFF;
const MASK_24: u64 = 0xFFFFFF;

fn nextLrand48(state: *u64) u32 {
    const low = state.* & MASK_24;
    const high = state.* >> 24;
    const high_product = (high * 0xECE66D) & MASK_24;
    state.* = (low * 0x5DEECE66D + (high_product << 24) + 0xB) & MASK_48;
    return @intCast(state.* >> 17);
}

fn differentExperiment(random_state: *u64, free_state: *[10]u8) bool {
    var faulty_state = free_state.*;
    for (0..10) |_| {
        const saved_free = free_state[0];
        const saved_faulty = faulty_state[0];
        var random_word = nextLrand48(random_state);
        for (0..9) |cell| {
            free_state[cell] = @intCast((@as(u32, free_state[cell + 1]) + random_word) & 1);
            const random_probability = nextLrand48(random_state);
            if (random_probability % 1000 < 250) random_word ^= 1;
            faulty_state[cell] = @intCast((@as(u32, faulty_state[cell + 1]) + random_word) & 1);
            random_word >>= 1;
        }
        random_word = nextLrand48(random_state);
        free_state[9] = @intCast((@as(u32, saved_free) + random_word) & 1);
        const random_probability = nextLrand48(random_state);
        if (random_probability % 10_000 < 2_500) random_word ^= 1;
        faulty_state[9] = @intCast((@as(u32, saved_faulty) + random_word) & 1);
    }
    for (0..10) |cell| if (free_state[cell] != faulty_state[cell]) return true;
    return false;
}

fn appendText(buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize, text: []const u8) void {
    for (text) |byte| { buffer[used.*] = byte; used.* += 1; }
}

fn appendUnsigned(buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize, value: u64) void {
    var remaining = value;
    var reverse: [24]u8 = undefined;
    var count: usize = 0;
    while (true) {
        reverse[count] = @intCast(48 + remaining % 10);
        count += 1;
        remaining /= 10;
        if (remaining == 0) break;
    }
    while (count > 0) { count -= 1; buffer[used.*] = reverse[count]; used.* += 1; }
}

fn appendProbability(buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize,
    same_count: u64, experiments: u64) void {
    var mantissa: u64 = 0;
    var exponent: i32 = 0;
    if (same_count != 0) {
        var scale: u64 = 1;
        while (same_count * scale < experiments) { scale *= 10; exponent -= 1; }
        const numerator = same_count * scale * 100_000_000;
        mantissa = numerator / experiments;
        const remainder = numerator % experiments;
        if (2 * remainder > experiments or (2 * remainder == experiments and mantissa & 1 != 0))
            mantissa += 1;
        if (mantissa == 1_000_000_000) { mantissa = 100_000_000; exponent += 1; }
    }
    const whole = mantissa / 100_000_000;
    var fraction = mantissa % 100_000_000;
    buffer[used.*] = @intCast(48 + whole); used.* += 1;
    buffer[used.*] = '.'; used.* += 1;
    var place: u64 = 10_000_000;
    for (0..8) |_| {
        buffer[used.*] = @intCast(48 + fraction / place); used.* += 1;
        fraction %= place;
        place /= 10;
    }
    buffer[used.*] = 'e'; used.* += 1;
    const absolute_exponent: u32 = @intCast(if (exponent < 0) -exponent else exponent);
    buffer[used.*] = if (exponent < 0) '-' else '+'; used.* += 1;
    buffer[used.*] = @intCast(48 + absolute_exponent / 10); used.* += 1;
    buffer[used.*] = @intCast(48 + absolute_exponent % 10); used.* += 1;
}

export fn mcgill_misr(experiments: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (experiments < MIN_EXPERIMENTS or experiments > MAX_EXPERIMENTS) return -1;
    if (output_opt == null) return -2;

    var random_state: u64 = 1;
    var free_state = [10]u8{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1 };
    var different_count: u64 = 0;
    for (0..@intCast(experiments)) |_| {
        if (differentExperiment(&random_state, &free_state)) different_count += 1;
    }

    var staged: [MAX_OUTPUT_BYTES]u8 = undefined;
    var used: usize = 0;
    appendText(&staged, &used, "reg_len #_vect prob #_tms struct seed1 seed2 seed3 Prob same output\n ");
    appendText(&staged, &used, "10 10 2.500e-01 ");
    appendUnsigned(&staged, &used, @intCast(experiments));
    appendText(&staged, &used, " 1000000000 1 0 0 ");
    appendProbability(&staged, &used, @as(u64, @intCast(experiments)) - different_count,
                      @intCast(experiments));
    staged[used] = '\n'; used += 1;

    if (output_capacity < used) return -2;
    const output = output_opt.?;
    for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}

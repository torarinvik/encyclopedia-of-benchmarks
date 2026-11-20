const SIDE: usize = 33;
const MAX_POINTS: usize = 17;
const GOLDEN: u64 = 0x9e3779b97f4a7c15;
const MULTIPLIER: u64 = 0x2545f4914f6cdd1d;

fn nextWord(state: *u64) u64 {
    state.* ^= state.* >> 12;
    state.* ^= state.* << 25;
    state.* ^= state.* >> 27;
    return state.* *% MULTIPLIER;
}

fn touches(occupied: *const [SIDE * SIDE]u8, x: usize, y: usize) bool {
    return occupied[y * SIDE + x - 1] != 0 or occupied[(y - 1) * SIDE + x] != 0 or
        occupied[y * SIDE + x + 1] != 0 or occupied[(y + 1) * SIDE + x] != 0;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn brownian_tree_diffusion_limited_aggregation(
    input_opt: ?[*]const i64,
    length: usize,
    output_opt: ?[*]u8,
    capacity: usize,
) i64 {
    const input = input_opt orelse return -1;
    if (length != 3) return -1;
    const attempts_value = input[0];
    const seed_value = input[1];
    const steps_value = input[2];
    if (attempts_value < 0 or attempts_value > 16 or seed_value < 1 or
        steps_value < 1 or steps_value > 512) return -1;

    var occupied: [SIDE * SIDE]u8 = @splat(0);
    var point_x: [MAX_POINTS]i32 = @splat(0);
    var point_y: [MAX_POINTS]i32 = @splat(0);
    var point_count: usize = 1;
    point_x[0] = 16;
    point_y[0] = 16;
    occupied[16 * SIDE + 16] = 1;

    for (0..@intCast(attempts_value)) |attempt| {
        var state = @as(u64, @intCast(seed_value)) ^ GOLDEN *% @as(u64, @intCast(attempt + 1));
        if (state == 0) state = MULTIPLIER;
        const side_draw = nextWord(&state);
        const position_draw = nextWord(&state);
        const launch_side: usize = @intCast(side_draw % 4);
        const position: usize = 1 + @as(usize, @intCast(position_draw % 31));
        var x: usize = undefined;
        var y: usize = undefined;
        switch (launch_side) {
            0 => { x = position; y = 1; },
            1 => { x = 31; y = position; },
            2 => { x = position; y = 31; },
            else => { x = 1; y = position; },
        }

        var at = y * SIDE + x;
        if (occupied[at] != 0) continue;
        if (touches(&occupied, x, y)) {
            occupied[at] = 1;
            point_x[point_count] = @intCast(x);
            point_y[point_count] = @intCast(y);
            point_count += 1;
            continue;
        }
        for (0..@intCast(steps_value)) |_| {
            switch (nextWord(&state) % 4) {
                0 => x -= 1,
                1 => y -= 1,
                2 => x += 1,
                else => y += 1,
            }
            if (x == 0 or x == 32 or y == 0 or y == 32) break;
            at = y * SIDE + x;
            if (touches(&occupied, x, y)) {
                occupied[at] = 1;
                point_x[point_count] = @intCast(x);
                point_y[point_count] = @intCast(y);
                point_count += 1;
                break;
            }
        }
    }

    const required = (1 + 2 * point_count) * 8;
    const output = output_opt orelse return -2;
    if (capacity < required) return -2;
    storeI64Le(output, 0, @intCast(point_count));
    for (0..point_count) |point| {
        storeI64Le(output, (1 + 2 * point) * 8, point_x[point]);
        storeI64Le(output, (2 + 2 * point) * 8, point_y[point]);
    }
    return @intCast(required);
}

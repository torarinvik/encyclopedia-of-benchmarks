const max_n: usize = 256;

const IntervalState = struct {
    output: []u8,
    count: usize = 0,
    last_hi: usize = 0,
    last_value: i32 = 0,
    has_last: bool = false,
};

fn valueAt(index: usize, step: i64, offset: i64, divisor: i64) i32 {
    return @intCast(@divTrunc(step * @as(i64, @intCast(index)) + offset, divisor));
}

fn storeI32Le(output: []u8, position: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[position + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn appendInterval(state: *IntervalState, lo: usize, hi: usize, value: i32) void {
    if (state.has_last and state.last_hi == lo and state.last_value == value) {
        storeI32Le(state.output, (state.count - 1) * 12 + 4, @intCast(hi));
    } else {
        const position = state.count * 12;
        storeI32Le(state.output, position, @intCast(lo));
        storeI32Le(state.output, position + 4, @intCast(hi));
        storeI32Le(state.output, position + 8, value);
        state.count += 1;
    }
    state.last_hi = hi;
    state.last_value = value;
    state.has_last = true;
}

fn visitRange(lo: usize, hi: usize, step: i64, offset: i64, divisor: i64,
              state: *IntervalState) void {
    const first = valueAt(lo, step, offset, divisor);
    const last = valueAt(hi - 1, step, offset, divisor);
    if (first == last or hi - lo == 1) {
        appendInterval(state, lo, hi, first);
        return;
    }
    const mid = lo + (hi - lo) / 2;
    visitRange(lo, mid, step, offset, divisor, state);
    visitRange(mid, hi, step, offset, divisor, state);
}

export fn constant_intervals(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length != 4) return -1;
    const values = input[0..length];
    const n_value = values[0];
    const step = values[1];
    const offset = values[2];
    const divisor = values[3];
    if (n_value < 0 or n_value > @as(i64, @intCast(max_n)) or step < 0 or step > 65535
        or offset < 0 or offset > 65535 or divisor < 1 or divisor > 65535) return -1;
    const n: usize = @intCast(n_value);
    const maximum_bytes = n * 12;
    if (output_capacity < maximum_bytes or (maximum_bytes > 0 and output == null)) return -2;
    if (n == 0) return 0;
    var state = IntervalState{ .output = output[0..maximum_bytes] };
    visitRange(0, n, step, offset, divisor, &state);
    return @intCast(state.count);
}

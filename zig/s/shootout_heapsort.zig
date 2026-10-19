const MAX_LENGTH: usize = 8192;
const OUTPUT_BYTES: usize = 9;
const MODULUS: i64 = 139968;
const MULTIPLIER: i64 = 3877;
const INCREMENT: i64 = 29573;

fn sourceHeapsort(n: usize, values: []f64) void {
    var ir = n;
    var l = (n / 2) + 1;
    while (true) {
        var rra: f64 = undefined;
        if (l > 1) {
            l -= 1;
            rra = values[l];
        } else {
            rra = values[ir];
            values[ir] = values[1];
            ir -= 1;
            if (ir == 1) {
                values[1] = rra;
                return;
            }
        }
        var i = l;
        var j = l * 2;
        while (j <= ir) {
            if (j < ir and values[j] < values[j + 1]) j += 1;
            if (rra < values[j]) {
                values[i] = values[j];
                i = j;
                j += i;
            } else {
                j = ir + 1;
            }
        }
        values[i] = rra;
    }
}

fn writeFixedSix(value: f64, output: [*]u8) void {
    const millionths: u32 = @intFromFloat(value * 1_000_000.0 + 0.5);
    const whole = millionths / 1_000_000;
    var fraction = millionths % 1_000_000;
    output[0] = @intCast('0' + whole);
    output[1] = '.';
    var divisor: u32 = 100_000;
    for (2..8) |index| {
        output[index] = @intCast('0' + (fraction / divisor) % 10);
        divisor /= 10;
    }
    output[8] = '\n';
}

export fn shootout_heapsort(length: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > MAX_LENGTH) return -1;
    if (output_opt == null or output_capacity < OUTPUT_BYTES) return -2;

    const n: usize = @intCast(length);
    var values: [MAX_LENGTH + 1]f64 = undefined;
    var state: i64 = 42;
    for (1..n + 1) |index| {
        state = @mod(state * MULTIPLIER + INCREMENT, MODULUS);
        values[index] = 1.0 * @as(f64, @floatFromInt(state)) / @as(f64, @floatFromInt(MODULUS));
    }
    sourceHeapsort(n, values[0 .. n + 1]);
    writeFixedSix(values[n], output_opt.?);
    return OUTPUT_BYTES;
}

const MAX_ITERATIONS: i64 = 256;
const VECTOR_LENGTH: usize = 2048;

export fn misc_fp_convert(input: [*c]const f64, input_length: usize,
    output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_length != 1) return -1;
    const requested = input[0];
    if (requested != requested or requested < 1.0 or requested > @as(f64, @floatFromInt(MAX_ITERATIONS))) return -1;
    const iterations: i64 = @intFromFloat(requested);
    if (@as(f64, @floatFromInt(iterations)) != requested) return -1;
    if (output == null or output_capacity < 1) return -2;

    var x: [VECTOR_LENGTH]f32 = undefined;
    var y: [VECTOR_LENGTH]f32 = undefined;
    var a: f32 = 0.0;
    var b: f32 = 1.0;
    var total: f64 = 0.0;
    for (0..@intCast(iterations)) |iteration| {
        if (iteration % 10 != 0) {
            a = 0.0;
            b = 1.0;
        } else {
            a += 0.1;
            b += 0.2;
        }
        for (0..VECTOR_LENGTH) |index| {
            const as_f32: f32 = @floatFromInt(index);
            x[index] = a + as_f32;
            y[index] = b + as_f32;
        }
        var accumulator: f64 = 0.0;
        for (0..VECTOR_LENGTH) |index|
            accumulator += @as(f64, x[index]) * @as(f64, y[index]);
        total += accumulator;
    }
    output[0] = total;
    return 1;
}

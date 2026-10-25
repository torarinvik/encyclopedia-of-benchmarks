const MAX_ITERATIONS: i64 = 128;
const MAX_VECTOR_SIZE: usize = 64;

export fn misc_dt(input: [*c]const f64, input_length: usize,
    output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_length != 2) return -1;
    const requested_iterations = input[0];
    const requested_size = input[1];
    if (requested_iterations != requested_iterations or requested_iterations < 1.0 or
        requested_iterations > @as(f64, @floatFromInt(MAX_ITERATIONS))) return -1;
    const iterations: i64 = @intFromFloat(requested_iterations);
    if (@as(f64, @floatFromInt(iterations)) != requested_iterations) return -1;
    if (requested_size != requested_size or requested_size < 1.0 or
        requested_size > @as(f64, @floatFromInt(MAX_VECTOR_SIZE))) return -1;
    const size: usize = @intFromFloat(requested_size);
    if (@as(f64, @floatFromInt(size)) != requested_size) return -1;
    if (output == null or output_capacity < size) return -2;

    var numerator: [MAX_VECTOR_SIZE]f64 = undefined;
    var denominator: [MAX_VECTOR_SIZE]f64 = undefined;
    for (0..size) |index| {
        const cosine = @cos(@as(f32, @floatFromInt(size - index)));
        const sine = @sin(@as(f32, @floatFromInt(index)));
        numerator[index] = 1.0000001 * @as(f64, cosine);
        denominator[index] = 1.0 + 1e-10 * @as(f64, sine);
    }
    for (0..@intCast(iterations)) |_| {
        for (0..size) |index| numerator[index] /= denominator[index];
    }
    for (0..size) |index| output[index] = numerator[index];
    return @intCast(size);
}

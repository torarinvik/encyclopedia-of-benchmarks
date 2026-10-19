const MAX_ITERATIONS: i64 = 10_000;
const MATRIX_ELEMENTS: usize = 16;
const a = [_]f64{4.5, 1.3, 6.0, 4.1, 2.5, 7.2, 7.7, 1.7, 6.7, 1.3, 9.4, 1.3, 1.1, 2.2, 3.0, 2.1};
const b = [_]f64{1.0, 7.9, 5.1, 3.4, 6.6, 2.8, 5.4, 9.2, 5.0, 4.1, 4.1, 9.9, 8.4, 3.7, 9.5, 6.4};

export fn matmul_f64_4x4(input: [*c]const f64, input_length: usize,
    output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_length != 1) return -1;
    const requested = input[0];
    if (requested != requested or requested < 1.0 or requested > @as(f64, @floatFromInt(MAX_ITERATIONS))) return -1;
    const iterations: i64 = @intFromFloat(requested);
    if (@as(f64, @floatFromInt(iterations)) != requested) return -1;

    var staged: [MATRIX_ELEMENTS]f64 = undefined;
    for (0..@intCast(iterations)) |_| {
        for (0..4) |row| {
            for (0..4) |column| {
                var sum = a[row * 4] * b[column];
                sum += a[row * 4 + 1] * b[4 + column];
                sum += a[row * 4 + 2] * b[8 + column];
                sum += a[row * 4 + 3] * b[12 + column];
                staged[row * 4 + column] = sum;
            }
        }
    }
    if (output == null or output_capacity < MATRIX_ELEMENTS) return -2;
    for (0..MATRIX_ELEMENTS) |index| output[index] = staged[index];
    return @intCast(MATRIX_ELEMENTS);
}

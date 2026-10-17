const MAX_INPUT_LENGTH: usize = 129;

fn strassenMultiply(a: [*]const i64, b: [*]const i64, result: [*]i64, n: usize) void {
    if (n == 1) { result[0] = a[0] * b[0]; return; }
    const h = n / 2;
    var x: [16]i64 = undefined;
    var y: [16]i64 = undefined;
    var m1: [16]i64 = undefined;
    var m2: [16]i64 = undefined;
    var m3: [16]i64 = undefined;
    var m4: [16]i64 = undefined;
    var m5: [16]i64 = undefined;
    var m6: [16]i64 = undefined;
    var m7: [16]i64 = undefined;
    for (0..h) |r| for (0..h) |col| {
        const i = r * h + col;
        x[i] = a[r*n+col] + a[(r+h)*n+col+h];
        y[i] = b[r*n+col] + b[(r+h)*n+col+h];
    };
    strassenMultiply(&x[0], &y[0], &m1[0], h);
    for (0..h) |r| for (0..h) |col| {
        const i = r * h + col;
        x[i] = a[(r+h)*n+col] + a[(r+h)*n+col+h]; y[i] = b[r*n+col];
    };
    strassenMultiply(&x[0], &y[0], &m2[0], h);
    for (0..h) |r| for (0..h) |col| {
        const i = r * h + col;
        x[i] = a[r*n+col]; y[i] = b[r*n+col+h] - b[(r+h)*n+col+h];
    };
    strassenMultiply(&x[0], &y[0], &m3[0], h);
    for (0..h) |r| for (0..h) |col| {
        const i = r * h + col;
        x[i] = a[(r+h)*n+col+h]; y[i] = b[(r+h)*n+col] - b[r*n+col];
    };
    strassenMultiply(&x[0], &y[0], &m4[0], h);
    for (0..h) |r| for (0..h) |col| {
        const i = r * h + col;
        x[i] = a[r*n+col] + a[r*n+col+h]; y[i] = b[(r+h)*n+col+h];
    };
    strassenMultiply(&x[0], &y[0], &m5[0], h);
    for (0..h) |r| for (0..h) |col| {
        const i = r * h + col;
        x[i] = a[(r+h)*n+col] - a[r*n+col]; y[i] = b[r*n+col] + b[r*n+col+h];
    };
    strassenMultiply(&x[0], &y[0], &m6[0], h);
    for (0..h) |r| for (0..h) |col| {
        const i = r * h + col;
        x[i] = a[r*n+col+h] - a[(r+h)*n+col+h];
        y[i] = b[(r+h)*n+col] + b[(r+h)*n+col+h];
    };
    strassenMultiply(&x[0], &y[0], &m7[0], h);
    for (0..h) |r| for (0..h) |col| {
        const i = r * h + col;
        result[r*n+col] = m1[i] + m4[i] - m5[i] + m7[i];
        result[r*n+col+h] = m3[i] + m5[i];
        result[(r+h)*n+col] = m2[i] + m4[i];
        result[(r+h)*n+col+h] = m1[i] - m2[i] + m3[i] + m6[i];
    };
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn strassen_matrix_multiplication(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input_ptr = input.?;
    const n_value = input_ptr[0];
    if (n_value != 1 and n_value != 2 and n_value != 4 and n_value != 8) return -1;
    const n: usize = @intCast(n_value);
    const cells = n * n;
    if (length != 1 + 2 * cells) return -1;
    for (0..2 * cells) |i| if (input_ptr[1+i] < -2 or input_ptr[1+i] > 2) return -1;
    const output_bytes = 8 * cells;
    if (output == null or capacity < output_bytes) return -2;
    var result: [64]i64 = undefined;
    strassenMultiply(input_ptr + 1, input_ptr + 1 + cells, &result[0], n);
    const output_ptr = output.?;
    for (0..cells) |i| storeI64Le(output_ptr, i * 8, result[i]);
    return @intCast(output_bytes);
}

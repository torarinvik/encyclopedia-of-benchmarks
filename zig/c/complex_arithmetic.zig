const MAX_COMPONENT: i64 = 100_000;
const OUTPUT_BYTES: usize = 16;

fn storeI64Le(output: [*c]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn complex_arithmetic(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length != 5) return -1;
    const values = input[0..length];
    const operation = values[0];
    const ar = values[1]; const ai = values[2]; const br = values[3]; const bi = values[4];
    if (operation < 0 or operation > 5 or ar < -MAX_COMPONENT or ar > MAX_COMPONENT or
        ai < -MAX_COMPONENT or ai > MAX_COMPONENT or br < -MAX_COMPONENT or
        br > MAX_COMPONENT or bi < -MAX_COMPONENT or bi > MAX_COMPONENT) return -1;
    var real_result: i64 = 0;
    var imaginary_result: i64 = 0;
    switch (operation) {
        0 => { real_result = ar + br; imaginary_result = ai + bi; },
        1 => { real_result = ar - br; imaginary_result = ai - bi; },
        2 => { real_result = ar * br - ai * bi; imaginary_result = ar * bi + ai * br; },
        3 => {
            const denominator = br * br + bi * bi;
            if (denominator == 0) return -1;
            const real_numerator = ar * br + ai * bi;
            const imaginary_numerator = ai * br - ar * bi;
            if (@rem(real_numerator, denominator) != 0 or @rem(imaginary_numerator, denominator) != 0) return -1;
            real_result = @divTrunc(real_numerator, denominator);
            imaginary_result = @divTrunc(imaginary_numerator, denominator);
        },
        4 => { real_result = ar; imaginary_result = -ai; },
        5 => { real_result = if (ar == br and ai == bi) 1 else 0; },
        else => return -1,
    }
    if (output_capacity < OUTPUT_BYTES or output == null) return -2;
    storeI64Le(output, 0, real_result);
    storeI64Le(output, 8, imaginary_result);
    return 2;
}

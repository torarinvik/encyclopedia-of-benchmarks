const MAX_INPUT_LENGTH: usize = 64;
const MAX_ERRORS: usize = 60;

export fn pid(input: [*c]const f64, length: usize,
    output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or length < 5 or length > MAX_INPUT_LENGTH) return -1;
    const error_count = length - 4;
    const input_ptr = input;
    const kp64 = input_ptr[0];
    const ki64 = input_ptr[1];
    const kd64 = input_ptr[2];
    const dt64 = input_ptr[3];
    if (kp64 != kp64 or kp64 < -1.0 or kp64 > 1.0
        or ki64 != ki64 or ki64 < -1.0 or ki64 > 1.0
        or kd64 != kd64 or kd64 < -1.0 or kd64 > 1.0
        or dt64 != dt64 or (dt64 != 0.0 and (dt64 < 0.01 or dt64 > 1.0))
        or error_count < 1 or error_count > MAX_ERRORS) return -1;
    var errors: [MAX_ERRORS]f32 = undefined;
    for (0..error_count) |index| {
        const value = input_ptr[4 + index];
        if (value != value or value < -1.0 or value > 1.0) return -1;
        errors[index] = @floatCast(value);
    }
    if (output == null or output_capacity < error_count) return -2;

    const kp: f32 = @floatCast(kp64);
    const ki: f32 = @floatCast(ki64);
    const kd: f32 = @floatCast(kd64);
    const dt: f32 = @floatCast(dt64);
    var integral: f32 = 0.0;
    var last_error: f32 = 0.0;
    const output_ptr = output;
    for (0..error_count) |index| {
        const error = errors[index];
        const proportional = error * kp;
        var integral_step = error * dt;
        integral_step = integral_step * ki;
        integral = integral + integral_step;
        var derivative: f32 = 0.0;
        if (dt != 0.0) {
            const difference = error - last_error;
            const rate = difference / dt;
            derivative = rate * kd;
        }
        last_error = error;
        const partial = proportional + integral;
        const result = partial + derivative;
        output_ptr[index] = @floatCast(result);
    }
    return @intCast(error_count);
}

module pid;

const usz MAX_INPUT_LENGTH = 64;
const usz MAX_ERRORS = 60;

fn long pid(double* input, usz length, double* output, usz output_capacity)
    @export("pid") {
    if (input == null || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    usz error_count = length - 4;
    double kp64 = input[0], ki64 = input[1], kd64 = input[2], dt64 = input[3];
    if (kp64 != kp64 || kp64 < -1.0 || kp64 > 1.0
        || ki64 != ki64 || ki64 < -1.0 || ki64 > 1.0
        || kd64 != kd64 || kd64 < -1.0 || kd64 > 1.0
        || dt64 != dt64 || (dt64 != 0.0 && (dt64 < 0.01 || dt64 > 1.0))
        || error_count < 1 || error_count > MAX_ERRORS) return -1;

    float[MAX_ERRORS] errors;
    for (usz index = 0; index < error_count; index++) {
        double value = input[4 + index];
        if (value != value || value < -1.0 || value > 1.0) return -1;
        errors[index] = (float)value;
    }
    if (output == null || output_capacity < error_count) return -2;

    float kp = (float)kp64, ki = (float)ki64, kd = (float)kd64, dt = (float)dt64;
    float integral = 0.0, last_error = 0.0;
    for (usz index = 0; index < error_count; index++) {
        float error = errors[index];
        float proportional = error * kp;
        float integral_step = error * dt;
        integral_step = integral_step * ki;
        integral = integral + integral_step;
        float derivative = 0.0;
        if (dt != 0.0) {
            float difference = error - last_error;
            float rate = difference / dt;
            derivative = rate * kd;
        }
        last_error = error;
        float partial = proportional + integral;
        float result = partial + derivative;
        output[index] = (double)result;
    }
    return (long)error_count;
}

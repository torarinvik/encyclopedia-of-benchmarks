module momentum;

const usz MAX_LENGTH = 64;
const usz ITERATIONS = 100;
const double LEARNING_RATE = 0.01;
const double BETA = 0.9;

fn long momentum(double* input, usz length, double* output, usz output_capacity)
    @export("momentum") {
    if (input == null || length == 0 || length > MAX_LENGTH) return -1;
    double[MAX_LENGTH] values, velocity, gradient;
    for (usz index = 0; index < length; index++) {
        double value = input[index];
        if (value != value || value < -1000000.0 || value > 1000000.0) return -1;
        values[index] = value;
        velocity[index] = 0.0;
    }
    if (output == null || output_capacity < length) return -2;

    for (usz iteration = 0; iteration < ITERATIONS; iteration++) {
        for (usz index = 0; index < length; index++) gradient[index] = 2.0 * values[index];
        for (usz index = 0; index < length; index++) {
            velocity[index] = BETA * velocity[index] + gradient[index];
            values[index] -= LEARNING_RATE * velocity[index];
        }
    }
    for (usz index = 0; index < length; index++) output[index] = values[index];
    return (long)length;
}

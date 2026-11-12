module splash2_fft_six_step;

extern fn double cos(double value);
extern fn double sin(double value);

const usz MAX_SIDE = 8;
const usz MAX_POINTS = 64;
const usz MAX_INPUT = 129;
const usz MAX_OUTPUT = 128;
const double TAU = 6.283185307179586476925286766559;

fn void transpose(double* source, double* destination, usz side) {
    for (usz row = 0; row < side; row++) {
        for (usz column = 0; column < side; column++) {
            usz from = 2 * (row * side + column);
            usz to = 2 * (column * side + row);
            destination[to] = source[from];
            destination[to + 1] = source[from + 1];
        }
    }
}

fn void fft_row(double* data, usz base, usz side) {
    usz reverse = 0;
    for (usz position = 1; position < side; position++) {
        usz bit = side >> 1;
        while ((reverse & bit) != 0) { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if (position < reverse) {
            usz left = 2 * (base + position), right = 2 * (base + reverse);
            double temporary = data[left]; data[left] = data[right]; data[right] = temporary;
            temporary = data[left + 1]; data[left + 1] = data[right + 1]; data[right + 1] = temporary;
        }
    }
    for (usz block = 2; block <= side; block *= 2) {
        usz half = block / 2;
        double angle_step = TAU / (double)block;
        for (usz start = 0; start < side; start += block) {
            for (usz offset = 0; offset < half; offset++) {
                double angle = angle_step * (double)offset;
                double weight_real = cos(angle), weight_imag = -sin(angle);
                usz first = 2 * (base + start + offset);
                usz second = 2 * (base + start + offset + half);
                double product_real = weight_real * data[second] - weight_imag * data[second + 1];
                double product_imag = weight_real * data[second + 1] + weight_imag * data[second];
                double first_real = data[first], first_imag = data[first + 1];
                data[first] = first_real + product_real;
                data[first + 1] = first_imag + product_imag;
                data[second] = first_real - product_real;
                data[second + 1] = first_imag - product_imag;
            }
        }
    }
}

fn long splash2_fft_six_step(double* input, usz input_length, double* output,
                             usz output_capacity) @export("splash2_fft_six_step") {
    if (input == null || input_length < 9 || input_length > 130) return -1L;
    double side_value = input[0];
    if (!(side_value == 2.0 || side_value == 4.0 || side_value == 8.0)) return -1L;
    usz side = (usz)side_value;
    usz points = side * side;
    if (input_length != 1 + 2 * points) return -1L;
    for (usz i = 0; i < input_length; i++) {
        if (!(input[i] >= -8.0 && input[i] <= 8.0) && i != 0) return -1L;
        if (input[i] != input[i]) return -1L;
    }

    double[MAX_OUTPUT] first_matrix = zeroed;
    double[MAX_OUTPUT] second_matrix = zeroed;
    for (usz i = 0; i < 2 * points; i++) first_matrix[i] = input[i + 1];
    transpose(&first_matrix[0], &second_matrix[0], side);
    for (usz row = 0; row < side; row++) fft_row(&second_matrix[0], row * side, side);
    for (usz row = 0; row < side; row++) {
        for (usz column = 0; column < side; column++) {
            usz index = 2 * (row * side + column);
            double angle = TAU * (double)(row * column) / (double)points;
            double cosine = cos(angle), sine = sin(angle);
            double real = second_matrix[index], imag = second_matrix[index + 1];
            second_matrix[index] = cosine * real + sine * imag;
            second_matrix[index + 1] = cosine * imag - sine * real;
        }
    }
    transpose(&second_matrix[0], &first_matrix[0], side);
    for (usz row = 0; row < side; row++) fft_row(&first_matrix[0], row * side, side);
    transpose(&first_matrix[0], &second_matrix[0], side);

    usz needed = 2 * points;
    if (output == null || output_capacity < needed) return -2L;
    for (usz i = 0; i < needed; i++) output[i] = second_matrix[i];
    return (long)needed;
}

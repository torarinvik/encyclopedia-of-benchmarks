module mandelbrot;

const long INVALID_RESULT = -1;
const long OUTPUT_ERROR = -2;
const usz MAX_OUTPUT_BYTES = 256;

fn double rounded_multiply(double left, double right) @noinline {
    return left * right;
}

fn double rounded_add(double left, double right) @noinline {
    return left + right;
}

fn double rounded_subtract(double left, double right) @noinline {
    return left - right;
}

fn double rounded_divide(double left, double right) @noinline {
    return left / right;
}

fn double pixel_coordinate(double center, long position, long dimension,
                           double span) {
    double normalized = rounded_divide((double)position, (double)dimension);
    double centered = rounded_subtract(normalized, 0.5);
    double offset = rounded_multiply(centered, span);
    return rounded_add(center, offset);
}

fn long mandelbrot(long* input, usz input_length, uint8* output,
                   usz output_capacity) @export("mandelbrot") {
    if (input == null || input_length != 6) return INVALID_RESULT;

    long width = input[0];
    long height = input[1];
    long center_x_q = input[2];
    long center_y_q = input[3];
    long figure_width_q = input[4];
    long max_step = input[5];
    if (width < 1 || width > 16 || height < 1 || height > 16 ||
        center_x_q < -64 || center_x_q > 64 ||
        center_y_q < -64 || center_y_q > 64 ||
        figure_width_q < 1 || figure_width_q > 64 ||
        max_step < 2 || max_step > 64) return INVALID_RESULT;

    double center_x = (double)center_x_q / 16.0;
    double center_y = (double)center_y_q / 16.0;
    double figure_width = (double)figure_width_q / 16.0;
    double figure_height = rounded_multiply(
        rounded_divide(figure_width, (double)width), (double)height);
    uint8 rendered[MAX_OUTPUT_BYTES] = {0};
    usz output_index = 0;

    for (long image_x = 0; image_x < width; image_x++) {
        double figure_x = pixel_coordinate(center_x, image_x, width, figure_width);
        for (long image_y = 0; image_y < height; image_y++) {
            double figure_y = pixel_coordinate(center_y, image_y, height, figure_height);
            double a = figure_x;
            double b = figure_y;
            long current_step = 0;
            for (long step = 0; step < max_step; step++) {
                current_step = step;
                double a_squared = rounded_multiply(a, a);
                double b_squared = rounded_multiply(b, b);
                double difference = rounded_subtract(a_squared, b_squared);
                double a_new = rounded_add(difference, figure_x);
                double twice_a = rounded_multiply(2.0, a);
                double twice_a_times_b = rounded_multiply(twice_a, b);
                double b_new = rounded_add(twice_a_times_b, figure_y);
                a = a_new;
                b = b_new;

                double next_a_squared = rounded_multiply(a, a);
                double next_b_squared = rounded_multiply(b, b);
                double magnitude_squared = rounded_add(next_a_squared, next_b_squared);
                if (magnitude_squared > 4.0) break;
            }
            double distance = rounded_divide((double)current_step, (double)(max_step - 1));
            rendered[output_index] = distance >= 1.0 ? 0 : 255;
            output_index++;
        }
    }

    if (output == null || output_capacity < output_index) return OUTPUT_ERROR;
    for (usz index = 0; index < output_index; index++) output[index] = rendered[index];
    return (long)output_index;
}

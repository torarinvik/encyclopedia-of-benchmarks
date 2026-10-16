module wus_line;

const long COORDINATE_LIMIT = 64;
const long MAX_PIXELS = 258;

extern fn double floor(double value);

fn double fraction_part(double value) { return value - floor(value); }
fn double reverse_fraction_part(double value) { return 1.0 - fraction_part(value); }

fn void add_pixel(long* pixel_x, long* pixel_y, double* intensities, usz* count,
                  long x, long y, double intensity, bool steep) {
    if (steep) { long temporary = x; x = y; y = temporary; }
    if (intensity < 0.0) intensity = 0.0;
    if (intensity > 1.0) intensity = 1.0;
    pixel_x[count[0]] = x;
    pixel_y[count[0]] = y;
    intensities[count[0]] = intensity;
    count[0]++;
}

fn void add_endpoint(long* pixel_x, long* pixel_y, double* intensities, usz* count,
                     long x_pixel, long y_pixel, double y_end, double x_gap, bool steep) {
    double fractional_y = fraction_part(y_end);
    double complement = reverse_fraction_part(y_end);
    add_pixel(pixel_x, pixel_y, intensities, count, x_pixel, y_pixel,
              complement * x_gap, steep);
    add_pixel(pixel_x, pixel_y, intensities, count, x_pixel, y_pixel + 1,
              fractional_y * x_gap, steep);
}

fn void write_i32_le(char* output, usz offset, long value) {
    uint bits = (uint)(int)value;
    for (usz byte = 0; byte < 4; byte++)
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn void write_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long wus_line(long* values, usz length, char* output, usz output_capacity)
    @export("wus_line") {
    if (values == null || length != 4) return -1;
    for (usz index = 0; index < 4; index++)
        if (values[index] < -COORDINATE_LIMIT || values[index] > COORDINATE_LIMIT) return -1;

    long x0 = values[0], y0 = values[1], x1 = values[2], y1 = values[3];
    bool steep = (y1 - y0 < 0 ? y0 - y1 : y1 - y0) >
                 (x1 - x0 < 0 ? x0 - x1 : x1 - x0);
    if (steep) { long temporary = x0; x0 = y0; y0 = temporary;
                 temporary = x1; x1 = y1; y1 = temporary; }
    if (x0 > x1) { long temporary = x0; x0 = x1; x1 = temporary;
                   temporary = y0; y0 = y1; y1 = temporary; }

    double delta_x = (double)x1 - (double)x0;
    double delta_y = (double)y1 - (double)y0;
    double gradient = delta_x == 0.0 ? 1.0 : delta_y / delta_x;
    double first_x_end = floor((double)x0 + 0.5);
    double first_y_end = (double)y0 + gradient * (first_x_end - (double)x0);
    long first_x_pixel = (long)first_x_end;
    long first_y_pixel = (long)floor(first_y_end);
    double first_gap = reverse_fraction_part((double)x0 + 0.5);
    double second_x_end = floor((double)x1 + 0.5);
    double second_y_end = (double)y1 + gradient * (second_x_end - (double)x1);
    long second_x_pixel = (long)second_x_end;
    long second_y_pixel = (long)floor(second_y_end);
    double second_gap = fraction_part((double)x1 + 0.5);

    long[MAX_PIXELS] pixel_x = {};
    long[MAX_PIXELS] pixel_y = {};
    double[MAX_PIXELS] intensities = {};
    usz pixel_count = 0;
    add_endpoint(&pixel_x[0], &pixel_y[0], &intensities[0], &pixel_count,
                 first_x_pixel, first_y_pixel, first_y_end, first_gap, steep);
    add_endpoint(&pixel_x[0], &pixel_y[0], &intensities[0], &pixel_count,
                 second_x_pixel, second_y_pixel, second_y_end, second_gap, steep);

    double intersection_y = first_y_end + gradient;
    for (long x = first_x_pixel + 1; x < second_x_pixel; x++) {
        long y_floor = (long)floor(intersection_y);
        double fractional = fraction_part(intersection_y);
        double complement = reverse_fraction_part(intersection_y);
        add_pixel(&pixel_x[0], &pixel_y[0], &intensities[0], &pixel_count,
                  x, y_floor, complement, steep);
        add_pixel(&pixel_x[0], &pixel_y[0], &intensities[0], &pixel_count,
                  x, y_floor + 1, fractional, steep);
        intersection_y += gradient;
    }

    usz required = pixel_count * 16;
    if (output == null || output_capacity < required) return -2;
    for (usz index = 0; index < pixel_count; index++) {
        usz offset = index * 16;
        write_i32_le(output, offset, pixel_x[index]);
        write_i32_le(output, offset + 4, pixel_y[index]);
        write_f64_le(output, offset + 8, intensities[index]);
    }
    return (long)required;
}

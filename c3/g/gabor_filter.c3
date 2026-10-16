module gabor_filter;

extern fn double sin(double value);
extern fn double cos(double value);
extern fn double exp(double value);

const double PI = 3.14159265358979323846264338327950288;

fn void put_f32(uint8 *output, usz offset, double value) {
    float rounded = (float)value;
    uint bits = @bitcast(uint, rounded);
    for (usz byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8)(bits >> (8 * byte));
}

fn long gabor_filter(long *values, usz length, uint8 *output, usz capacity)
    @export("gabor_filter") {
    if (values == null || length < 1 || length > 7) return -1;
    if (length != 6) return -1;
    long requested = values[0], sigma = values[1], theta = values[2];
    long wavelength = values[3], gamma = values[4], phase = values[5];
    if (requested < 1 || requested > 7 || sigma < 1 || sigma > 8 ||
        theta < 0 || theta > 359 || wavelength < 1 || wavelength > 8 ||
        gamma < 0 || gamma > 4 || phase < -6 || phase > 6) return -1;

    usz side = (usz)requested;
    if (side % 2 == 0) ++side;
    usz output_bytes = side * side * 4;
    if (output == null || capacity < output_bytes) return -2;

    double angle = ((double)theta / 180.0) * PI;
    double cosine = cos(angle), sine = sin(angle);
    usz center = side / 2, offset = 0;
    for (usz y = 0; y < side; ++y) {
        double py = (double)y - (double)center;
        for (usz x = 0; x < side; ++x) {
            double px = (double)x - (double)center;
            double kernel_x = cosine * px + sine * py;
            double kernel_y = -sine * px + cosine * py;
            double exponent = -(kernel_x * kernel_x +
                (double)(gamma * gamma) * kernel_y * kernel_y) /
                (2.0 * (double)sigma * (double)sigma);
            double phase_angle = 2.0 * PI * kernel_x /
                (double)wavelength + (double)phase;
            put_f32(output, offset, exp(exponent) * cos(phase_angle));
            offset += 4;
        }
    }
    return (long)output_bytes;
}

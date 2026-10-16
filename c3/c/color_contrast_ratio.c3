module color_contrast_ratio;

extern fn double pow(double base, double exponent);
const double INVALID_RESULT = -1.0e300;

fn double component(long channel) {
    double srgb = (double)channel / 255.0;
    if (srgb <= 0.03928) return srgb / 12.92;
    double adjusted = (srgb + 0.055) / 1.055;
    return pow(adjusted, 2.4);
}

fn double luminance(long red, long green, long blue) {
    return 0.2126 * component(red) + 0.7152 * component(green) + 0.0722 * component(blue);
}

fn double color_contrast_ratio(long* values, usz length) @export("color_contrast_ratio") {
    if (values == null || length != 6) return INVALID_RESULT;
    for (usz i = 0; i < 6; i++) {
        if (values[i] < 0 || values[i] > 255) return INVALID_RESULT;
    }
    double first = luminance(values[0], values[1], values[2]);
    double second = luminance(values[3], values[4], values[5]);
    if (first > second) return (first + 0.05) / (second + 0.05);
    return (second + 0.05) / (first + 0.05);
}

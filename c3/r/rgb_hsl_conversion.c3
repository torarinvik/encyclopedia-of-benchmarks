module rgb_hsl_conversion;

const usz INPUT_COUNT = 3;
const usz OUTPUT_COUNT = 4;

fn long rgb_hsl_conversion(long* input, usz length, char* output, usz capacity) @export("rgb_hsl_conversion") {
    if (input == null || length != INPUT_COUNT) return -1;
    for (usz i = 0; i < INPUT_COUNT; i++) if (input[i] < 0 || input[i] > 255) return -1;
    if (output == null || capacity < OUTPUT_COUNT) return -2;

    double red = (double)input[0] / 255.0;
    double green = (double)input[1] / 255.0;
    double blue = (double)input[2] / 255.0;
    double minimum = red, maximum = red;
    if (green < minimum) minimum = green;
    if (blue < minimum) minimum = blue;
    if (green > maximum) maximum = green;
    if (blue > maximum) maximum = blue;
    int channel = 0;
    if (maximum == green) channel = 1;
    else if (maximum == blue) channel = 2;
    double luminance = (minimum + maximum) / 2.0;
    double saturation = 0.0;
    if (minimum != maximum) {
        if (luminance <= 0.5) saturation = (maximum - minimum) / (maximum + minimum);
        else saturation = (maximum - minimum) / (2.0 - maximum - minimum);
    }
    double hue = 0.0;
    if (saturation != 0.0) {
        if (channel == 0) hue = (green - blue) / (maximum - minimum);
        else if (channel == 1) hue = 2.0 + (blue - red) / (maximum - minimum);
        else hue = 4.0 + (red - green) / (maximum - minimum);
    }
    hue *= 60.0;
    if (hue < 0.0) hue += 360.0;
    uint h = (uint)(hue + 0.5);
    output[0] = (char)(h & 255);
    output[1] = (char)(h >> 8);
    output[2] = (char)(saturation * 100.0 + 0.5);
    output[3] = (char)(luminance * 100.0 + 0.5);
    return (long)OUTPUT_COUNT;
}

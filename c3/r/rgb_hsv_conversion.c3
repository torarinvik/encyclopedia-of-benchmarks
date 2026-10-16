module rgb_hsv_conversion;

fn void write_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz i = 0; i < 8; i++) { output[offset + i] = (char)(bits & 255); bits >>= 8; }
}

fn long rgb_hsv_conversion(long* input, usz length, char* output, usz capacity) @export("rgb_hsv_conversion") {
    if (input == null || length != 3) return -1;
    for (usz i = 0; i < 3; i++) if (input[i] < 0 || input[i] > 255) return -1;
    if (output == null || capacity < 24) return -2;
    double red = (double)input[0] / 255.0, green = (double)input[1] / 255.0, blue = (double)input[2] / 255.0;
    double value = red > green ? red : green;
    if (blue > value) value = blue;
    double minimum = red < green ? red : green;
    if (blue < minimum) minimum = blue;
    double chroma = value - minimum;
    double saturation = value == 0.0 ? 0.0 : chroma / value;
    double hue;
    if (chroma == 0.0) hue = 0.0;
    else if (value == red) hue = 60.0 * (0.0 + (green - blue) / chroma);
    else if (value == green) hue = 60.0 * (2.0 + (blue - red) / chroma);
    else hue = 60.0 * (4.0 + (red - green) / chroma);
    hue += 360.0;
    if (hue >= 360.0) hue -= 360.0;
    write_f64_le(output, 0, hue);
    write_f64_le(output, 8, saturation);
    write_f64_le(output, 16, value);
    return 24;
}

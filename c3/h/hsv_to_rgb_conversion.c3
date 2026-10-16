module hsv_to_rgb_conversion;

fn double section_remainder_two(double section) {
    if (section < 2.0) return section;
    if (section < 4.0) return section - 2.0;
    if (section < 6.0) return section - 4.0;
    return section - 6.0;
}

fn char round_channel(double channel) {
    return (char)(255.0 * channel + 0.5);
}

fn long hsv_to_rgb_conversion(long* input, usz length, char* output, usz capacity) @export("hsv_to_rgb_conversion") {
    if (input == null || length != 3) return -1;
    if (input[0] < 0 || input[0] > 360000 || input[1] < 0 || input[1] > 255000000 ||
        input[2] < 0 || input[2] > 255000000) return -1;
    if (output == null || capacity < 3) return -2;

    double hue = (double)input[0] / 1000.0;
    double saturation = (double)input[1] / 255000000.0;
    double value = (double)input[2] / 255000000.0;
    double chroma = value * saturation;
    double hue_section = hue / 60.0;
    double remainder = section_remainder_two(hue_section);
    double delta = remainder - 1.0;
    double absolute_delta = delta < 0.0 ? -delta : delta;
    double second = chroma * (1.0 - absolute_delta);
    double matched = value - chroma;
    double red, green, blue;
    if (hue_section >= 0.0 && hue_section <= 1.0) {
        red=chroma+matched; green=second+matched; blue=matched;
    } else if (hue_section > 1.0 && hue_section <= 2.0) {
        red=second+matched; green=chroma+matched; blue=matched;
    } else if (hue_section > 2.0 && hue_section <= 3.0) {
        red=matched; green=chroma+matched; blue=second+matched;
    } else if (hue_section > 3.0 && hue_section <= 4.0) {
        red=matched; green=second+matched; blue=chroma+matched;
    } else if (hue_section > 4.0 && hue_section <= 5.0) {
        red=second+matched; green=matched; blue=chroma+matched;
    } else {
        red=chroma+matched; green=matched; blue=second+matched;
    }
    output[0]=(char)(255.0*red+0.5);
    output[1]=(char)(255.0*green+0.5);
    output[2]=(char)(255.0*blue+0.5);
    return 3;
}

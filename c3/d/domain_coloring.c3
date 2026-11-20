module domain_coloring;

fn long dc_phase_hue(long real_part, long imaginary_part) {
    if (real_part == 0 && imaginary_part == 0) return 0;
    long abs_real = real_part < 0 ? -real_part : real_part;
    long abs_imaginary = imaginary_part < 0 ? -imaginary_part : imaginary_part;
    long high = abs_real > abs_imaginary ? abs_real : abs_imaginary;
    long low = abs_real < abs_imaginary ? abs_real : abs_imaginary;
    long step = 192 * low / high;
    long hue;
    if (imaginary_part >= 0) {
        if (real_part >= 0) hue = abs_real >= abs_imaginary ? step : 384 - step;
        else hue = abs_real < abs_imaginary ? 384 + step : 768 - step;
    } else if (real_part < 0) {
        hue = abs_real >= abs_imaginary ? 768 + step : 1152 - step;
    } else {
        hue = abs_real < abs_imaginary ? 1152 + step : 1536 - step;
    }
    return hue == 1536 ? 0 : hue;
}

fn void dc_store_pixel(uint8[MAX_OUTPUT_BYTES]* pixels, usz offset,
                       long hue, long magnitude_16) {
    long value = 128 + 8 * (magnitude_16 % 16);
    long sector = hue / 256;
    long fraction = hue % 256;
    uint8 rising = (uint8)(value * fraction / 255);
    uint8 falling = (uint8)(value * (255 - fraction) / 255);
    uint8 bright = (uint8)value;
    uint8 red = 0, green = 0, blue = 0;
    switch (sector) {
    case 0: red = bright; green = rising; break;
    case 1: red = falling; green = bright; break;
    case 2: green = bright; blue = rising; break;
    case 3: green = falling; blue = bright; break;
    case 4: red = rising; blue = bright; break;
    default: red = bright; blue = falling; break;
    }
    (*pixels)[offset] = red;
    (*pixels)[offset + 1] = green;
    (*pixels)[offset + 2] = blue;
}

fn long domain_coloring(long* input, usz input_length, uint8* output,
                        usz output_capacity) @export("domain_coloring") {
    if (input == null || input_length != 6) return -1;
    long width_value = input[0], height_value = input[1];
    long x_start = input[2], y_start = input[3];
    long x_step = input[4], y_step = input[5];
    if (width_value < 1 || width_value > 16 || height_value < 1 || height_value > 16 ||
        x_start < -32 || x_start > 32 || y_start < -32 || y_start > 32 ||
        x_step < -8 || x_step > 8 || y_step < -8 || y_step > 8) return -1;
    long x_end = x_start + (width_value - 1) * x_step;
    long y_end = y_start + (height_value - 1) * y_step;
    if (x_end < -32 || x_end > 32 || y_end < -32 || y_end > 32) return -1;

    usz width = (usz)width_value, height = (usz)height_value;
    usz byte_count = 3 * width * height;
    uint8[MAX_OUTPUT_BYTES] rendered = zeroed;
    usz offset = 0;
    for (usz row = 0; row < height; row++) {
        long y_q = y_start + (long)row * y_step;
        for (usz column = 0; column < width; column++) {
            long x_q = x_start + (long)column * x_step;
            long x_squared = x_q * x_q, y_squared = y_q * y_q;
            dc_store_pixel(&rendered, offset,
                dc_phase_hue(x_squared - y_squared, 2 * x_q * y_q),
                x_squared + y_squared);
            offset += 3;
        }
    }
    if (output == null || output_capacity < byte_count) return -2;
    for (usz index = 0; index < byte_count; index++) output[index] = rendered[index];
    return (long)byte_count;
}

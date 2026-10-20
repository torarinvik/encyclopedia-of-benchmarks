// Adapted from Trekhleb's seam-carving explanation. Copyright (c) 2018
// Oleksii Trekhleb; MIT License, see benchmarks/s/seam_carving/LICENSE.txt.
module seam_carving;

extern fn double sqrt(double value);

long seam_carving(long* input, usz length, char* output, usz output_capacity)
        @export("seam_carving") {
    if (input == null || length < 2 || length > 39) return -1;
    long width_value = input[0], height_value = input[1];
    if (width_value < 2 || width_value > 6 || height_value < 1 || height_value > 6) return -1;
    usz width = (usz)width_value, height = (usz)height_value;
    if (length != 2 + width * height) return -1;
    for (usz i = 0; i < width * height; i++)
        if (input[2 + i] < 0 || input[2 + i] > 255) return -1;

    double[6][6] energy = zeroed;
    double[6][6] cumulative = zeroed;
    long[6][6] previous_x = zeroed;
    usz[6] seam_x = zeroed;
    for (usz y = 0; y < height; y++) {
        usz row = y * width;
        for (usz x = 0; x < width; x++) {
            double middle = (double)input[2 + row + x];
            double left_energy = 0.0, right_energy = 0.0;
            if (x > 0) {
                double difference = (double)input[2 + row + x - 1] - middle;
                left_energy = difference * difference + difference * difference + difference * difference;
            }
            if (x + 1 < width) {
                double difference = (double)input[2 + row + x + 1] - middle;
                right_energy = difference * difference + difference * difference + difference * difference;
            }
            energy[y][x] = sqrt(left_energy + right_energy);
        }
    }
    for (usz x = 0; x < width; x++) cumulative[0][x] = energy[0][x];
    for (usz y = 1; y < height; y++) {
        for (usz x = 0; x < width; x++) {
            double minimum = 1.0e300;
            usz best_x = x;
            usz start = x == 0 ? 0 : x - 1;
            usz end = x + 1 < width ? x + 1 : width - 1;
            for (usz candidate = start; candidate <= end; candidate++) {
                if (cumulative[y - 1][candidate] < minimum) {
                    minimum = cumulative[y - 1][candidate];
                    best_x = candidate;
                }
            }
            cumulative[y][x] = minimum + energy[y][x];
            previous_x[y][x] = (long)best_x;
        }
    }
    usz last_x = 0;
    double minimum = cumulative[height - 1][0];
    for (usz x = 1; x < width; x++) {
        if (cumulative[height - 1][x] < minimum) {
            minimum = cumulative[height - 1][x];
            last_x = x;
        }
    }
    seam_x[height - 1] = last_x;
    for (usz y = height - 1; y > 0; y--)
        seam_x[y - 1] = (usz)previous_x[y][seam_x[y]];

    usz needed = height * (width - 1);
    if (output == null || output_capacity < needed) return -2;
    u8[30] staged = zeroed;
    usz position = 0;
    for (usz y = 0; y < height; y++) {
        for (usz x = 0; x < width; x++) {
            if (x != seam_x[y]) {
                staged[position] = (u8)input[2 + y * width + x];
                position++;
            }
        }
    }
    for (usz i = 0; i < needed; i++) output[i] = (char)staged[i];
    return (long)needed;
}

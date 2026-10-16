module canny;

const long NORM_SCALE = 1048576;
const long ANGLE_SCALE = 1000000000;
const long TAN_22_5_Q9 = 414213562;
fn long canny_clamp(int coordinate, usz side) {
    if (coordinate < 0) return 0;
    if ((usz)coordinate >= side) return (long)(side - 1);
    return coordinate;
}

fn ulong canny_isqrt(ulong value) {
    if (value < 2) return value;
    ulong low = 1;
    ulong high = value < 4294967296 ? value : 4294967296;
    while (low <= high) {
        ulong middle = low + (high - low) / 2;
        if (middle <= value / middle) {
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    return high;
}

fn long canny(long* values, usz length, char* output, usz output_capacity) @export("canny") {
    if (values == null || length < 2 || length > 257) return -1;
    long side_value = values[0];
    if (side_value < 1 || side_value > 16) return -1;
    usz side = (usz)side_value;
    usz pixels = side * side;
    if (length != pixels + 1) return -1;
    for (usz i = 0; i < pixels; i++) {
        if (values[i + 1] < 0 || values[i + 1] > 255) return -1;
    }
    if (output_capacity < pixels || output == null) return -2;

    const long[25] GAUSSIAN = {
        85321, 66110, 30754, 8589, 1440,
        66110, 51225, 23829, 6655, 1116,
        30754, 23829, 11085, 3096, 519,
        8589, 6655, 3096, 865, 145,
        1440, 1116, 519, 145, 24
    };
    const int[9] SOBEL_X = {-1, 0, 1, -2, 0, 2, -1, 0, 1};
    const int[9] SOBEL_Y = {1, 2, 1, 0, 0, 0, -1, -2, -1};
    long[256] blurred;
    long[256] gradient_x;
    long[256] gradient_y;
    long[256] normalized_x;
    long[256] normalized_y;
    long[256] magnitude;
    long[256] destination;
    for (usz i = 0; i < 256; i++) {
        blurred[i] = 0;
        gradient_x[i] = 0;
        gradient_y[i] = 0;
        normalized_x[i] = 0;
        normalized_y[i] = 0;
        magnitude[i] = 0;
        destination[i] = 0;
    }

    for (usz row = 0; row < side; row++) {
        for (usz column = 0; column < side; column++) {
            long total = 0;
            for (int ky = -4; ky <= 4; ky++) {
                usz source_row = (usz)canny_clamp((int)row + ky, side);
                for (int kx = -4; kx <= 4; kx++) {
                    usz source_column = (usz)canny_clamp((int)column + kx, side);
                    int ay = ky < 0 ? -ky : ky;
                    int ax = kx < 0 ? -kx : kx;
                    total += GAUSSIAN[ay * 5 + ax] * values[1 + source_row * side + source_column];
                }
            }
            blurred[row * side + column] = total;
        }
    }

    long maximum_x = 0;
    long maximum_y = 0;
    for (usz row = 0; row < side; row++) {
        for (usz column = 0; column < side; column++) {
            long total_x = 0;
            long total_y = 0;
            for (int ky = -1; ky <= 1; ky++) {
                usz source_row = (usz)canny_clamp((int)row + ky, side);
                for (int kx = -1; kx <= 1; kx++) {
                    usz source_column = (usz)canny_clamp((int)column + kx, side);
                    long sample = blurred[source_row * side + source_column];
                    int kernel_index = (ky + 1) * 3 + kx + 1;
                    total_x += sample * SOBEL_X[kernel_index];
                    total_y += sample * SOBEL_Y[kernel_index];
                }
            }
            if (total_x < 0) total_x = -total_x;
            if (total_y < 0) total_y = -total_y;
            usz offset = row * side + column;
            gradient_x[offset] = total_x;
            gradient_y[offset] = total_y;
            if (total_x > maximum_x) maximum_x = total_x;
            if (total_y > maximum_y) maximum_y = total_y;
        }
    }

    ulong maximum_magnitude = 0;
    for (usz i = 0; i < pixels; i++) {
        if (maximum_x != 0) normalized_x[i] = gradient_x[i] * 255 * NORM_SCALE / maximum_x;
        if (maximum_y != 0) normalized_y[i] = gradient_y[i] * 255 * NORM_SCALE / maximum_y;
        ulong x = (ulong)normalized_x[i];
        ulong y = (ulong)normalized_y[i];
        magnitude[i] = (long)canny_isqrt(x * x + y * y);
        if ((ulong)magnitude[i] > maximum_magnitude) maximum_magnitude = (ulong)magnitude[i];
    }
    if (maximum_magnitude != 0) {
        for (usz i = 0; i < pixels; i++) magnitude[i] = magnitude[i] * 255 / (long)maximum_magnitude;
    }

    for (usz row = 1; row + 1 < side; row++) {
        for (usz column = 1; column + 1 < side; column++) {
            usz offset = row * side + column;
            usz before;
            usz after;
            if (normalized_y[offset] * ANGLE_SCALE < normalized_x[offset] * TAN_22_5_Q9) {
                before = offset - 1; after = offset + 1;
            } else if (normalized_x[offset] * ANGLE_SCALE <= normalized_y[offset] * TAN_22_5_Q9) {
                before = offset - side; after = offset + side;
            } else {
                before = offset + side - 1; after = offset - side + 1;
            }
            if (magnitude[offset] >= magnitude[before] && magnitude[offset] >= magnitude[after]) {
                destination[offset] = magnitude[offset];
            }
        }
    }
    for (usz i = 0; i < pixels; i++) {
        if (destination[i] >= 30) {
            destination[i] = 255;
        } else if (destination[i] <= 15) {
            destination[i] = 0;
        } else {
            destination[i] = 128;
        }
    }
    for (usz row = 1; row + 1 < side; row++) {
        for (usz column = 1; column + 1 < side; column++) {
            usz offset = row * side + column;
            if (destination[offset] == 128) {
                bool connected = false;
                for (int dy = -1; dy <= 1; dy++) {
                    for (int dx = -1; dx <= 1; dx++) {
                        if ((dx != 0 || dy != 0)
                            && destination[(usz)((int)row + dy) * side + (usz)((int)column + dx)] == 255) {
                            connected = true;
                        }
                    }
                }
                destination[offset] = connected ? 255 : 0;
            }
        }
    }
    for (usz i = 0; i < pixels; i++) output[i] = (char)destination[i];
    return (long)pixels;
}

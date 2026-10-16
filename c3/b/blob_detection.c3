module blob_detection;

const usz MAX_SIDE = 128;
const usz MAX_CELLS = MAX_SIDE * MAX_SIDE;
const usz MAX_INPUT_LENGTH = 3 + 3 * MAX_CELLS;

fn bool is_target_color(long red, long green, long blue, long profile) {
    long maximum = red > green ? red : green;
    if (blue > maximum) maximum = blue;
    long minimum = red < green ? red : green;
    if (blue < minimum) minimum = blue;
    long delta = maximum - minimum;
    long hue_minimum = profile == 0 ? 379 : 398;
    long hue_maximum = profile == 0 ? 496 : 498;
    long saturation_minimum = profile == 0 ? 436 : 355;
    if (maximum == 0 || delta == 0 || 1000 * delta < saturation_minimum * maximum) return false;

    long hue_numerator;
    if (maximum == red) {
        hue_numerator = (green - blue) % (6 * delta);
        if (hue_numerator < 0) hue_numerator += 6 * delta;
    } else if (maximum == green) {
        hue_numerator = 2 * delta + blue - red;
    } else {
        hue_numerator = 4 * delta + red - green;
    }
    return hue_minimum * 6 * delta <= 1000 * hue_numerator &&
           1000 * hue_numerator <= hue_maximum * 6 * delta;
}

fn long blob_detection(long* input, usz length) @export("blob_detection") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long height_value = input[0];
    long width_value = input[1];
    long profile = input[2];
    if (height_value < 1 || height_value > (long)MAX_SIDE ||
        width_value < 1 || width_value > (long)MAX_SIDE) return -1;
    usz height = (usz)height_value;
    usz width = (usz)width_value;
    usz cells = height * width;
    if ((profile != 0 && profile != 1) || length != 3 + 3 * cells) return -1;
    for (usz channel = 0; channel < 3 * cells; channel++) {
        if (input[3 + channel] < 0 || input[3 + channel] > 255) return -1;
    }

    bool[MAX_CELLS] mask;
    bool[MAX_CELLS] eroded;
    bool[MAX_CELLS] opened;
    bool[MAX_CELLS] visited;
    ushort[MAX_CELLS] queue;
    for (usz index = 0; index < cells; index++) {
        mask[index] = is_target_color(input[3 + 3 * index], input[4 + 3 * index],
                                      input[5 + 3 * index], profile);
        eroded[index] = false;
        opened[index] = false;
        visited[index] = false;
    }

    for (usz row = 0; row < height; row++) {
        for (usz column = 0; column < width; column++) {
            bool keep = true;
            for (long dy = -3; dy <= 3 && keep; dy++) {
                for (long dx = -3; dx <= 3; dx++) {
                    if (dx * dx + dy * dy > 9) continue;
                    long y = (long)row + dy;
                    long x = (long)column + dx;
                    if (y >= 0 && y < height_value && x >= 0 && x < width_value &&
                        !mask[(usz)y * width + (usz)x]) {
                        keep = false;
                        break;
                    }
                }
            }
            eroded[row * width + column] = keep;
        }
    }

    for (usz row = 0; row < height; row++) {
        for (usz column = 0; column < width; column++) {
            bool set = false;
            for (long dy = -3; dy <= 3 && !set; dy++) {
                for (long dx = -3; dx <= 3; dx++) {
                    if (dx * dx + dy * dy > 9) continue;
                    long y = (long)row + dy;
                    long x = (long)column + dx;
                    if (y >= 0 && y < height_value && x >= 0 && x < width_value &&
                        eroded[(usz)y * width + (usz)x]) {
                        set = true;
                        break;
                    }
                }
            }
            opened[row * width + column] = set;
        }
    }

    long object_count = 0;
    for (usz start = 0; start < cells; start++) {
        if (!opened[start] || visited[start]) continue;
        usz head = 0;
        usz tail = 0;
        usz area = 0;
        visited[start] = true;
        queue[tail++] = (ushort)start;
        while (head < tail) {
            usz index = (usz)queue[head++];
            area++;
            long row = (long)(index / width);
            long column = (long)(index % width);
            for (long dy = -1; dy <= 1; dy++) {
                for (long dx = -1; dx <= 1; dx++) {
                    if (dx == 0 && dy == 0) continue;
                    long y = row + dy;
                    long x = column + dx;
                    if (y < 0 || y >= height_value || x < 0 || x >= width_value) continue;
                    usz neighbor = (usz)y * width + (usz)x;
                    if (opened[neighbor] && !visited[neighbor]) {
                        visited[neighbor] = true;
                        queue[tail++] = (ushort)neighbor;
                    }
                }
            }
        }
        if (area >= 200 && area <= 5000) {
            object_count++;
            if (object_count == 50) return object_count;
        }
    }
    return object_count;
}

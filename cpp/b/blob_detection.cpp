#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 128
#define MAX_CELLS (MAX_SIDE * MAX_SIDE)
#define MAX_INPUT_LENGTH (3 + 3 * MAX_CELLS)
#define DISK_RADIUS 3

static int is_target_color(int64_t red_value, int64_t green_value, int64_t blue_value,
                           int64_t profile) {
    int red = (int)red_value;
    int green = (int)green_value;
    int blue = (int)blue_value;
    int maximum = red > green ? red : green;
    if (blue > maximum) maximum = blue;
    int minimum = red < green ? red : green;
    if (blue < minimum) minimum = blue;
    int delta = maximum - minimum;
    int64_t hue_minimum = profile == 0 ? 379 : 398;
    int64_t hue_maximum = profile == 0 ? 496 : 498;
    int64_t saturation_minimum = profile == 0 ? 436 : 355;
    if (maximum == 0 || delta == 0 || 1000 * delta < saturation_minimum * maximum) return 0;

    int hue_numerator;
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

extern "C" int64_t blob_detection(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    int64_t height_value = input[0];
    int64_t width_value = input[1];
    int64_t profile = input[2];
    if (height_value < 1 || height_value > MAX_SIDE ||
        width_value < 1 || width_value > MAX_SIDE) return -1;
    size_t height = (size_t)height_value;
    size_t width = (size_t)width_value;
    size_t cells = height * width;
    if ((profile != 0 && profile != 1) || length != 3 + 3 * cells) return -1;
    for (size_t channel = 0; channel < 3 * cells; ++channel) {
        if (input[3 + channel] < 0 || input[3 + channel] > 255) return -1;
    }

    uint8_t mask[MAX_CELLS] = {0};
    uint8_t eroded[MAX_CELLS] = {0};
    uint8_t opened[MAX_CELLS] = {0};
    uint8_t visited[MAX_CELLS] = {0};
    size_t queue[MAX_CELLS];

    for (size_t index = 0; index < cells; ++index) {
        mask[index] = (uint8_t)is_target_color(input[3 + 3 * index],
                                               input[4 + 3 * index],
                                               input[5 + 3 * index], profile);
    }

    for (size_t row = 0; row < height; ++row) {
        for (size_t column = 0; column < width; ++column) {
            int keep = 1;
            for (int dy = -DISK_RADIUS; dy <= DISK_RADIUS && keep; ++dy) {
                for (int dx = -DISK_RADIUS; dx <= DISK_RADIUS; ++dx) {
                    if (dx * dx + dy * dy > DISK_RADIUS * DISK_RADIUS) continue;
                    int64_t y = (int64_t)row + dy;
                    int64_t x = (int64_t)column + dx;
                    if (y >= 0 && y < height_value && x >= 0 && x < width_value &&
                        mask[(size_t)y * width + (size_t)x] == 0) {
                        keep = 0;
                        break;
                    }
                }
            }
            eroded[row * width + column] = (uint8_t)keep;
        }
    }

    for (size_t row = 0; row < height; ++row) {
        for (size_t column = 0; column < width; ++column) {
            int set = 0;
            for (int dy = -DISK_RADIUS; dy <= DISK_RADIUS && !set; ++dy) {
                for (int dx = -DISK_RADIUS; dx <= DISK_RADIUS; ++dx) {
                    if (dx * dx + dy * dy > DISK_RADIUS * DISK_RADIUS) continue;
                    int64_t y = (int64_t)row + dy;
                    int64_t x = (int64_t)column + dx;
                    if (y >= 0 && y < height_value && x >= 0 && x < width_value &&
                        eroded[(size_t)y * width + (size_t)x] != 0) {
                        set = 1;
                        break;
                    }
                }
            }
            opened[row * width + column] = (uint8_t)set;
        }
    }

    int64_t object_count = 0;
    for (size_t start = 0; start < cells; ++start) {
        if (opened[start] == 0 || visited[start] != 0) continue;
        size_t head = 0;
        size_t tail = 0;
        size_t area = 0;
        visited[start] = 1;
        queue[tail++] = start;
        while (head < tail) {
            size_t index = queue[head++];
            ++area;
            int64_t row = (int64_t)(index / width);
            int64_t column = (int64_t)(index % width);
            for (int dy = -1; dy <= 1; ++dy) {
                for (int dx = -1; dx <= 1; ++dx) {
                    if (dx == 0 && dy == 0) continue;
                    int64_t y = row + dy;
                    int64_t x = column + dx;
                    if (y < 0 || y >= height_value || x < 0 || x >= width_value) continue;
                    size_t neighbor = (size_t)y * width + (size_t)x;
                    if (opened[neighbor] != 0 && visited[neighbor] == 0) {
                        visited[neighbor] = 1;
                        queue[tail++] = neighbor;
                    }
                }
            }
        }
        if (area >= 200 && area <= 5000) {
            ++object_count;
            if (object_count == 50) return object_count;
        }
    }
    return object_count;
}

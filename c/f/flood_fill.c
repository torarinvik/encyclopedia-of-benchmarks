#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 32
#define MAX_CELLS (MAX_SIDE * MAX_SIDE)
#define MAX_INPUT_LENGTH (6 + MAX_CELLS)

static void put_i64(uint8_t *output, size_t index, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[index * 8 + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t flood_fill(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 6 || length > MAX_INPUT_LENGTH) return -1;
    int64_t width_value = input[0], height_value = input[1];
    int64_t start_x_value = input[2], start_y_value = input[3];
    int64_t new_color = input[4], target_color = input[5];
    if (width_value < 1 || width_value > MAX_SIDE || height_value < 1 || height_value > MAX_SIDE
        || new_color < INT32_MIN || new_color > INT32_MAX
        || target_color < INT32_MIN || target_color > INT32_MAX || new_color == target_color) return -1;
    size_t width = (size_t)width_value, height = (size_t)height_value;
    if (length != 6 + width * height || start_x_value < 0 || start_x_value >= width_value
        || start_y_value < 0 || start_y_value >= height_value) return -1;

    int64_t image[MAX_CELLS];
    for (size_t index = 0; index < width * height; ++index) {
        image[index] = input[6 + index];
        if (image[index] < INT32_MIN || image[index] > INT32_MAX) return -1;
    }
    size_t start = (size_t)start_x_value * height + (size_t)start_y_value;
    if (image[start] == target_color) {
        size_t stack[MAX_CELLS], top = 0;
        image[start] = new_color;
        stack[top++] = start;
        while (top != 0) {
            size_t index = stack[--top];
            size_t x = index / height, y = index % height;
            for (int dx = -1; dx <= 1; ++dx) {
                for (int dy = -1; dy <= 1; ++dy) {
                    if (dx == 0 && dy == 0) continue;
                    int64_t next_x = (int64_t)x + dx, next_y = (int64_t)y + dy;
                    if (next_x < 0 || next_x >= width_value || next_y < 0 || next_y >= height_value) continue;
                    size_t next = (size_t)next_x * height + (size_t)next_y;
                    if (image[next] == target_color) {
                        image[next] = new_color;
                        stack[top++] = next;
                    }
                }
            }
        }
    }
    size_t cells = width * height, required = cells * 8;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < cells; ++index) put_i64(output, index, image[index]);
    return (int64_t)required;
}

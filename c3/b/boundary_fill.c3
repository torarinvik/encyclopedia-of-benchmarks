module boundary_fill;

const long MAX_SIDE = 32;
const usz MAX_CELLS = 1024;

fn void put_i64(usz index, long value, char* output) {
    ulong bits = (ulong)value;
    for (usz offset = 0; offset < 8; offset++) output[index * 8 + offset] = (char)(bits >> (offset * 8));
}

fn long boundary_fill(long* input, usz length, char* output, usz capacity) @export("boundary_fill") {
    if (input == null || length < 6 || length > 1030) return -1;
    long width_value = input[0];
    long height_value = input[1];
    long start_x_value = input[2];
    long start_y_value = input[3];
    long new_color = input[4];
    long boundary_color = input[5];
    if (width_value < 1 || width_value > MAX_SIDE || height_value < 1 || height_value > MAX_SIDE
        || new_color < -2147483648 || new_color > 2147483647
        || boundary_color < -2147483648 || boundary_color > 2147483647) return -1;
    usz width = (usz)width_value;
    usz height = (usz)height_value;
    if (length != 6 + width * height || start_x_value < 0 || start_x_value >= width_value
        || start_y_value < 0 || start_y_value >= height_value) return -1;
    long[MAX_CELLS] image;
    for (usz index = 0; index < width * height; index++) {
        image[index] = input[6 + index];
        if (image[index] < -2147483648 || image[index] > 2147483647) return -1;
    }
    usz start = (usz)start_x_value * height + (usz)start_y_value;
    if (image[start] != new_color && image[start] != boundary_color) {
    usz[MAX_CELLS] stack;
        usz top = 0;
        image[start] = new_color;
        stack[top++] = start;
        while (top > 0) {
            usz index = stack[--top];
            long x = (long)(index / height);
            long y = (long)(index % height);
            for (long dx = -1; dx <= 1; dx++) {
                for (long dy = -1; dy <= 1; dy++) {
                    if (dx == 0 && dy == 0) continue;
                    long next_x = x + dx;
                    long next_y = y + dy;
                    if (next_x < 0 || next_x >= width_value || next_y < 0 || next_y >= height_value) continue;
                    usz next = (usz)next_x * height + (usz)next_y;
                    if (image[next] != new_color && image[next] != boundary_color) {
                        image[next] = new_color;
                        stack[top++] = next;
                    }
                }
            }
        }
    }
    usz cells = width * height;
    usz required = cells * 8;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < cells; index++) put_i64(index, image[index], output);
    return (long)required;
}

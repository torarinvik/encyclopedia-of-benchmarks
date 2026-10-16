module circular_look_scheduling;

const usz MAX_REQUESTS = 64;
const long MAX_CYLINDER_COUNT = 128;

fn void sort_ascending(long* items, usz count) {
    for (usz index = 1; index < count; index += 1) {
        long value = items[index];
        usz position = index;
        while (position > 0 && items[position - 1] > value) {
            items[position] = items[position - 1];
            position -= 1;
        }
        items[position] = value;
    }
}

fn long circular_look_scheduling(long* values, usz length, char* output, usz output_capacity)
    @export("circular_look_scheduling") {
    if (values == null || length < 4 || length > 4 + MAX_REQUESTS) return -1;
    long max_cylinder = values[0];
    long start = values[1];
    long moving_up = values[2];
    long request_count = values[3];
    if (max_cylinder < 1 || max_cylinder > MAX_CYLINDER_COUNT || start < 0 || start >= max_cylinder ||
        (moving_up != 0 && moving_up != 1) || request_count < 0 || request_count > (long)MAX_REQUESTS ||
        length != 4 + (usz)request_count) return -1;

    long[MAX_REQUESTS] up;
    long[MAX_REQUESTS] down;
    usz up_count = 0;
    usz down_count = 0;
    for (usz index = 0; index < (usz)request_count; index += 1) {
        long request = values[4 + index];
        if (request < -128 || request > 255) return -1;
        if (request < 0 || request >= max_cylinder || request == start) continue;
        if (request > start) {
            up[up_count] = request;
            up_count += 1;
        } else {
            down[down_count] = request;
            down_count += 1;
        }
    }
    sort_ascending(&up[0], up_count);
    sort_ascending(&down[0], down_count);

    usz output_count = up_count + down_count;
    if (output_capacity < output_count || (output_count > 0 && output == null)) return -2;
    usz position = 0;
    if (moving_up == 1) {
        for (usz index = 0; index < up_count; index += 1) {
            output[position] = (char)up[index];
            position += 1;
        }
        for (usz index = 0; index < down_count; index += 1) {
            output[position] = (char)down[index];
            position += 1;
        }
    } else {
        for (usz index = down_count; index > 0; index -= 1) {
            output[position] = (char)down[index - 1];
            position += 1;
        }
        for (usz index = up_count; index > 0; index -= 1) {
            output[position] = (char)up[index - 1];
            position += 1;
        }
    }
    return (long)output_count;
}

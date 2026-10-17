module skyline_algorithm;

const usz MAX_POINT_COUNT = 64;
const usz MAX_PARSEABLE_INPUT_VALUES = 130;
const usz MAX_OUTPUT_BYTES = 513;
const long MIN_I32 = -2147483648;
const long MAX_I32 = 2147483647;

fn bool dominates(long left_x, long left_y, long right_x, long right_y) {
    return (left_x < right_x && left_y <= right_y) ||
           (left_x <= right_x && left_y < right_y);
}

fn usz produce_skyline(long* xs, long* ys, usz start, usz count,
                       long* output_x, long* output_y) {
    if (count == 1) {
        output_x[0] = xs[start];
        output_y[0] = ys[start];
        return 1;
    }
    if (count == 2) {
        if (dominates(xs[start], ys[start], xs[start + 1], ys[start + 1])) {
            output_x[0] = xs[start];
            output_y[0] = ys[start];
            return 1;
        }
        if (dominates(xs[start + 1], ys[start + 1], xs[start], ys[start])) {
            output_x[0] = xs[start + 1];
            output_y[0] = ys[start + 1];
            return 1;
        }
        output_x[0] = xs[start];
        output_y[0] = ys[start];
        output_x[1] = xs[start + 1];
        output_y[1] = ys[start + 1];
        return 2;
    }

    usz middle = count / 2;
    long[MAX_POINT_COUNT] left_x = zeroed;
    long[MAX_POINT_COUNT] left_y = zeroed;
    long[MAX_POINT_COUNT] right_x = zeroed;
    long[MAX_POINT_COUNT] right_y = zeroed;
    usz left_count = produce_skyline(xs, ys, start, middle,
                                     &left_x[0], &left_y[0]);
    usz right_count = produce_skyline(xs, ys, start + middle, count - middle,
                                      &right_x[0], &right_y[0]);

    // Match the source's adjacent same-x cleanup of the left frontier.
    usz index = 0;
    while (index + 1 < left_count) {
        if (left_x[index] == left_x[index + 1] && left_y[index] > left_y[index + 1]) {
            for (usz move = index; move + 1 < left_count; move++) {
                left_x[move] = left_x[move + 1];
                left_y[move] = left_y[move + 1];
            }
            left_count--;
            if (index > 0) index--;
        } else {
            index++;
        }
    }

    long minimum_y = left_y[0];
    for (index = 1; index < left_count; index++) {
        if (minimum_y > left_y[index]) {
            minimum_y = left_y[index];
            if (minimum_y == 1) break;
        }
    }

    index = 0;
    while (index < right_count) {
        if (right_y[index] >= minimum_y) {
            for (usz move = index; move + 1 < right_count; move++) {
                right_x[move] = right_x[move + 1];
                right_y[move] = right_y[move + 1];
            }
            right_count--;
        } else {
            index++;
        }
    }

    for (index = 0; index < left_count; index++) {
        output_x[index] = left_x[index];
        output_y[index] = left_y[index];
    }
    for (usz right_index = 0; right_index < right_count; right_index++) {
        output_x[left_count + right_index] = right_x[right_index];
        output_y[left_count + right_index] = right_y[right_index];
    }
    return left_count + right_count;
}

fn void write_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long skyline_algorithm(long* input, usz input_length,
                          char* output, usz output_capacity)
    @export("skyline_algorithm")
{
    if (input == null || input_length < 3 ||
        input_length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_POINT_COUNT) return -1;

    usz point_count = (usz)input[0];
    if (input_length != 1 + 2 * point_count) return -1;

    long[MAX_POINT_COUNT] xs = zeroed;
    long[MAX_POINT_COUNT] ys = zeroed;
    for (usz index = 0; index < point_count; index++) {
        long x = input[1 + 2 * index];
        long y = input[2 + 2 * index];
        if (x < MIN_I32 || x > MAX_I32 || y < 1 || y > MAX_I32) return -1;
        if (index > 0 && x <= input[1 + 2 * (index - 1)]) return -1;
        xs[index] = x;
        ys[index] = y;
    }

    long[MAX_POINT_COUNT] skyline_x = zeroed;
    long[MAX_POINT_COUNT] skyline_y = zeroed;
    usz skyline_count = produce_skyline(&xs[0], &ys[0], 0, point_count,
                                        &skyline_x[0], &skyline_y[0]);
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    staged[0] = (char)skyline_count;
    for (usz index = 0; index < skyline_count; index++) {
        usz offset = 1 + 8 * index;
        write_i32_le(&staged[0], offset, (int)skyline_x[index]);
        write_i32_le(&staged[0], offset + 4, (int)skyline_y[index]);
    }

    usz output_length = 1 + 8 * skyline_count;
    if (output == null || output_capacity < output_length) return -2;
    for (usz index = 0; index < output_length; index++) output[index] = staged[index];
    return (long)output_length;
}

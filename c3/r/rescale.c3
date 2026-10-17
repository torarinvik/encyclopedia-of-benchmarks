module rescale;

const usz MAX_DRAWS = 256;
const usz MAX_INPUT_LENGTH = 260;

fn long rescale(long* input, usz length) @export("rescale") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long max_value = input[0], new_max = input[1], draw_count = input[2];
    if (max_value < 2 || max_value > 64 || new_max < 1 || new_max > 256
        || draw_count < 1 || draw_count > (long)MAX_DRAWS) return -1;
    if (length != 3 + (usz)draw_count) return -1;
    for (usz i = 0; i < (usz)draw_count; i++) {
        if (input[3 + i] < 0 || input[3 + i] >= max_value) return -1;
    }

    usz cursor = 0;
    if (new_max == max_value) return input[3];

    if (new_max < max_value) {
        long threshold = max_value - max_value % new_max;
        while (cursor < (usz)draw_count) {
            long draw = input[3 + cursor];
            cursor++;
            if (draw < threshold) return draw % new_max;
        }
        return -1;
    }

    long result = 0, power = 1;
    while (power < new_max) {
        if (cursor >= (usz)draw_count) return -1;
        result += power * input[3 + cursor];
        cursor++;
        power *= max_value;
    }
    if (power == new_max) return result;

    long threshold = power - power % new_max;
    while (result >= threshold) {
        result = 0;
        power = 1;
        while (power < new_max) {
            if (cursor >= (usz)draw_count) return -1;
            result += power * input[3 + cursor];
            cursor++;
            power *= max_value;
        }
    }
    return result % new_max;
}

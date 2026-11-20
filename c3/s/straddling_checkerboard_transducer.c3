module straddling_checkerboard_transducer;

const usz MAX_INPUT = 97;
const usz MAX_TEXT = 64;
const usz BOARD_SIZE = 30;
const usz MAX_OUTPUT = 128;

fn bool parse_board(long* input, usz length, usz* hole_a, usz* hole_b,
                   long* text_length, long* mode) {
    if (input == null || length < 32 || length > MAX_INPUT) return false;
    *mode = input[0];
    if (*mode != 0 && *mode != 1) return false;
    usz holes = 0;
    for (usz position = 0; position < BOARD_SIZE; position++) {
        long value = input[1 + position];
        if (position < 10 && value == 0) {
            if (holes == 0) *hole_a = position;
            else if (holes == 1) *hole_b = position;
            holes++;
            continue;
        }
        if (value < 32 || value > 126) return false;
        for (usz prior = 0; prior < position; prior++)
            if (input[1 + prior] == value) return false;
    }
    if (holes != 2) return false;
    *text_length = input[31];
    if (*text_length < 0 || *text_length > (long)MAX_TEXT) return false;
    return length == (usz)(32 + *text_length);
}

fn long find_symbol(long* input, long value) {
    for (usz position = 0; position < BOARD_SIZE; position++)
        if (input[1 + position] != 0 && input[1 + position] == value) return (long)position;
    return -1;
}

fn bool measure_decode(long* input, long text_length, usz hole_a, usz hole_b,
                      usz* result_length) {
    *result_length = 0;
    for (long index = 0; index < text_length; index++) {
        long value = input[32 + (usz)index];
        if (value < '0' || value > '9') return false;
        usz column = (usz)(value - '0');
        if (input[1 + column] != 0) {
            *result_length = *result_length + 1;
            continue;
        }
        if (index + 1 >= text_length) return false;
        long next = input[32 + (usz)index + 1];
        if (next < '0' || next > '9' || (column != hole_a && column != hole_b)) return false;
        *result_length = *result_length + 1;
        index++;
    }
    return true;
}

fn long straddling_checkerboard_transducer(long* input, usz length,
        char* output, usz output_capacity) @export("straddling_checkerboard_transducer") {
    usz hole_a = 0, hole_b = 0;
    long text_length = 0, mode = -1;
    if (!parse_board(input, length, &hole_a, &hole_b, &text_length, &mode)) return -1;

    usz result_length = 0;
    if (mode == 0) {
        for (long index = 0; index < text_length; index++) {
            long position = find_symbol(input, input[32 + (usz)index]);
            if (position < 0) return -1;
            result_length += position < 10 ? 1 : 2;
        }
    } else if (!measure_decode(input, text_length, hole_a, hole_b, &result_length)) {
        return -1;
    }

    if (result_length > MAX_OUTPUT) return -1;
    if (output == null || output_capacity < result_length) return -2;
    if (mode == 0) {
        usz out = 0;
        for (long index = 0; index < text_length; index++) {
            long position = find_symbol(input, input[32 + (usz)index]);
            if (position < 10) output[out++] = (char)('0' + position);
            else {
                usz row_digit = position < 20 ? hole_a : hole_b;
                output[out++] = (char)('0' + row_digit);
                output[out++] = (char)('0' + position % 10);
            }
        }
    } else {
        usz out = 0;
        for (long index = 0; index < text_length; index++) {
            usz column = (usz)(input[32 + (usz)index] - '0');
            if (input[1 + column] != 0) output[out++] = (char)input[1 + column];
            else {
                usz row = column == hole_a ? 1 : 2;
                usz next_column = (usz)(input[32 + (usz)(++index)] - '0');
                output[out++] = (char)input[1 + row * 10 + next_column];
            }
        }
    }
    return (long)result_length;
}

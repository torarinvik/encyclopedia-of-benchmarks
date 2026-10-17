module pipeline;

const usz MAX_STAGE_COUNT = 32;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_STAGE_COUNT;

fn long pipeline(long* values, usz length) @export("pipeline") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;

    long initial = values[0];
    long stage_count = values[1];
    if (initial < 0 || initial > 2 || stage_count < 1 || stage_count > 32) return -1;
    if (length != (usz)(2 + 2 * stage_count)) return -1;

    long result = initial;
    for (long index = 0; index < stage_count; index++) {
        long operation = values[2 + 2 * index];
        long argument = values[3 + 2 * index];
        if (argument < 0 || argument > 2) return -1;
        if (operation == 0) result += argument;
        else if (operation == 1) result *= argument;
        else return -1;
    }
    return result;
}

const MAX_ARRAY_LENGTH: usz = 256;
const MAX_INPUT_LENGTH: usz = MAX_ARRAY_LENGTH + 1;
const INT32_MIN_VALUE: long = -2147483648;
const INT32_MAX_VALUE: long = 2147483647;

fn long how_many_times_rotated(long* input, usz length) @export("how_many_times_rotated") {
    if (length > MAX_INPUT_LENGTH) return -1;
    if (length > MAX_ARRAY_LENGTH) return -1;
    if (length == 0) return 0;
    if (input == null) return -1;
    for (usz index = 0; index < length; index++) {
        if (input[index] < INT32_MIN_VALUE || input[index] > INT32_MAX_VALUE) return -1;
    }

    usz low = 0;
    usz high = length == 0 ? 0 : length - 1;
    while (low < high) {
        usz middle = low + (high - low) / 2;
        if (input[middle] > input[high]) low = middle + 1;
        else high = middle;
    }
    return (long)low;
}

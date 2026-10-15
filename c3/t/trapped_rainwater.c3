module trapped_rainwater;

const usz MAX_LENGTH = 4096;
const long MAX_HEIGHT = 1000000;

// Sum water trapped between bounded, nonnegative elevation bars.
fn long trapped_rainwater(long* heights, usz length) @export("trapped_rainwater") {
    if (length > MAX_LENGTH || (length != 0 && heights == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (heights[index] < 0 || heights[index] > MAX_HEIGHT) return -1;
    }
    if (length < 3) return 0;

    long[MAX_LENGTH] left_max;
    long[MAX_LENGTH] right_max;
    left_max[0] = heights[0];
    for (usz index = 1; index < length; index++) {
        left_max[index] = left_max[index - 1] > heights[index] ? left_max[index - 1] : heights[index];
    }
    right_max[length - 1] = heights[length - 1];
    usz index = length - 1;
    while (index > 0) {
        index--;
        right_max[index] = right_max[index + 1] > heights[index] ? right_max[index + 1] : heights[index];
    }

    long water = 0;
    for (usz position = 0; position < length; position++) {
        long boundary = left_max[position] < right_max[position] ? left_max[position] : right_max[position];
        water += boundary - heights[position];
    }
    return water;
}

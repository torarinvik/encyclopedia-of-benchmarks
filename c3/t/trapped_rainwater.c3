module trapped_rainwater;

const usz MAX_LENGTH = 4096;
const usz SHORT_LENGTH = 16;
const ulong MAX_HEIGHT = 1000000;

fn long trapped_water_with_suffix(long* heights, usz length, uint* suffix) {
    uint boundary = 0;
    for (usz index = length; index > 0;) {
        index--;
        ulong raw = (ulong)heights[index];
        if (raw > MAX_HEIGHT) return -1;
        uint height = (uint)raw;
        boundary = height > boundary ? height : boundary;
        suffix[index] = boundary;
    }

    uint water = 0;
    boundary = 0;
    for (usz index = 0; index < length; index++) {
        uint height = (uint)heights[index];
        boundary = height > boundary ? height : boundary;
        uint wall = suffix[index] < boundary ? suffix[index] : boundary;
        water += wall - height;
    }
    return (long)water;
}

// Sum water trapped between bounded, nonnegative elevation bars.
fn long trapped_rainwater(long* heights, usz length) @export("trapped_rainwater") {
    if (length > MAX_LENGTH || (length != 0 && heights == null)) return -1;
    if (length <= SHORT_LENGTH) {
        uint[SHORT_LENGTH] suffix;
        return trapped_water_with_suffix(heights, length, &suffix[0]);
    }
    uint[MAX_LENGTH] suffix;
    return trapped_water_with_suffix(heights, length, &suffix[0]);
}

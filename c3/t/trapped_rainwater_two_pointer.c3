module trapped_rainwater_two_pointer;

const usz MAX_LENGTH = 4096;

// Sum trapped water by advancing the side with the smaller current boundary.
fn long trapped_rainwater_two_pointer(long* heights, usz length)
    @export("trapped_rainwater_two_pointer") {
    if (length > MAX_LENGTH || (length != 0 && heights == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (heights[index] < 0 || heights[index] > 1000000) return -1;
    }
    if (length <= 2) return 0;

    usz left = 0;
    usz right = length - 1;
    uint left_max = 0;
    uint right_max = 0;
    uint trapped = 0;
    while (left < right) {
        if (heights[left] < heights[right]) {
            uint height = (uint)heights[left];
            if (height >= left_max) left_max = height;
            else trapped += left_max - height;
            left++;
        } else {
            uint height = (uint)heights[right];
            if (height >= right_max) right_max = height;
            else trapped += right_max - height;
            right--;
        }
    }
    return (long)trapped;
}

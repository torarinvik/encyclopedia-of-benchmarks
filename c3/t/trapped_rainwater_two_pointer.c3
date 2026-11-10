module trapped_rainwater_two_pointer;

fn long trapped_rainwater_two_pointer(long* heights, usz length)
    @export("trapped_rainwater_two_pointer") {
    if (length > 4096 || (length != 0 && heights == null)) return -1;
    if (length == 0) return 0;

    usz left = 0;
    usz right = length - 1;
    ulong left_height = (ulong)heights[left];
    ulong right_height = (ulong)heights[right];
    if (left_height > 1000000 || right_height > 1000000) return -1;

    uint left_max = 0;
    uint right_max = 0;
    uint trapped = 0;
    while (left < right) {
        if (left_height < right_height) {
            uint height = (uint)left_height;
            left_max = height > left_max ? height : left_max;
            trapped += left_max - height;
            left_height = (ulong)heights[++left];
            if (left_height > 1000000) return -1;
        } else {
            uint height = (uint)right_height;
            right_max = height > right_max ? height : right_max;
            trapped += right_max - height;
            right_height = (ulong)heights[--right];
            if (right_height > 1000000) return -1;
        }
    }
    return (long)trapped;
}

module container_with_most_water;

// Two-pointer maximum area between vertical lines.
fn long container_with_most_water(long* heights, usz length) @export("container_with_most_water") {
    if (length > 4096) return -1;
    for (usz index = 0; index < length; index++) {
        if (heights[index] < 0 || heights[index] > 2147483647) return -1;
    }
    if (length < 2) return 0;

    usz left = 0;
    usz right = length - 1;
    long best = 0;
    while (left < right) {
        long left_height = heights[left];
        long right_height = heights[right];
        long height = left_height < right_height ? left_height : right_height;
        long area = height * (long)(right - left);
        if (area > best) best = area;
        if (left_height <= right_height) { left++; }
        else { right--; }
    }
    return best;
}

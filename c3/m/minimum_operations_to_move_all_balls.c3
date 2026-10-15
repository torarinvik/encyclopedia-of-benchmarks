module min_operations_move_balls;

// Return each box's movement count as a 16-bit little-endian value.
fn long minimum_operations_to_move_all_balls(long* boxes, usz length, char* output, usz output_capacity)
        @export("minimum_operations_to_move_all_balls") {
    if (length > 256 || (length != 0 && boxes == null)) return -1;
    long right_ones = 0;
    long right_distance = 0;
    for (usz index = 0; index < length; index++) {
        long value = boxes[index];
        if (value != 0 && value != 1) return -1;
        if (value == 1) {
            right_ones++;
            right_distance += (long)index;
        }
    }
    usz required_capacity = length * 2;
    if (output_capacity < required_capacity) return -2;
    long left_ones = 0;
    long left_distance = 0;
    for (usz index = 0; index < length; index++) {
        if (boxes[index] == 1) {
            right_ones--;
            left_ones++;
        }
        long distance = left_distance + right_distance;
        output[2 * index] = (char)(distance & 255);
        output[2 * index + 1] = (char)((distance >> 8) & 255);
        right_distance -= right_ones;
        left_distance += left_ones;
    }
    return (long)length;
}

module sorted_rotated_check;

fn long check_if_array_is_sorted_and_rotated(long* values, usz length)
    @export("check_if_array_is_sorted_and_rotated")
{
    if (length > 256 || (length != 0 && values == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -2147483648 || values[index] > 2147483647) return -1;
    }
    if (length == 0) return 1;
    usz descents = 0;
    for (usz index = 0; index < length; index++) {
        usz next = (index + 1) % length;
        if (values[index] > values[next]) {
            descents++;
            if (descents > 1) return 0;
        }
    }
    return 1;
}

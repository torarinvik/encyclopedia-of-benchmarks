module longest_alternating_subsequence;

const usz MAX_LENGTH = 512;

// Return the length of the strict longest alternating subsequence.
fn long longest_alternating_subsequence(long* values, usz length) @export("longest_alternating_subsequence")
{
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -1;
    long[MAX_LENGTH] rising;
    long[MAX_LENGTH] falling;
    long result = 1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -2147483648 || values[index] > 2147483647) return -1;
        rising[index] = 1;
        falling[index] = 1;
        for (usz previous = 0; previous < index; previous++) {
            if (values[previous] < values[index] && rising[index] < falling[previous] + 1) {
                rising[index] = falling[previous] + 1;
            }
            if (values[previous] > values[index] && falling[index] < rising[previous] + 1) {
                falling[index] = rising[previous] + 1;
            }
        }
        if (rising[index] > result) result = rising[index];
        if (falling[index] > result) result = falling[index];
    }
    return result;
}

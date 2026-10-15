module median;

// Return twice the statistical median using a local insertion-sorted copy.
fn long median(long* values, usz length) @export("median")
{
    if (length == 0 || length > 1024) return 0;
    long[1024] ordered;
    for (usz index = 0; index < length; index++) ordered[index] = values[index];
    for (usz index = 1; index < length; index++) {
        long value = ordered[index];
        usz cursor = index;
        while (cursor > 0 && ordered[cursor - 1] > value) {
            ordered[cursor] = ordered[cursor - 1];
            cursor--;
        }
        ordered[cursor] = value;
    }
    if (length % 2 != 0) return ordered[length / 2] * 2;
    return ordered[length / 2 - 1] + ordered[length / 2];
}

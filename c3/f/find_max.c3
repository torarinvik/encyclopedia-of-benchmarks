module find_max;

// Return the largest signed value in a nonempty array.
fn long find_max(long* values, usz length) @export("find_max")
{
    if (length == 0 || length > 512) return -1;
    long result = values[0];
    for (usz index = 1; index < length; index++) {
        if (values[index] > result) result = values[index];
    }
    return result;
}

module find_min;

// Return the smallest signed value in a nonempty array.
fn long find_min(long* values, usz length) @export("find_min")
{
    if (length == 0 || length > 512) return -1;
    long result = values[0];
    for (usz index = 1; index < length; index++) {
        if (values[index] < result) result = values[index];
    }
    return result;
}

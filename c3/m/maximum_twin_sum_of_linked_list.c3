module maximum_twin_sum_of_linked_list;

const MAX_LENGTH = 1024;

// Copy positive list values, then scan each mirrored twin pair.
fn long maximum_twin_sum_of_linked_list(long* values, usz length) @export("maximum_twin_sum_of_linked_list") {
    if (values == null || length < 2 || length > MAX_LENGTH || length % 2 != 0) { return -1; }
    int[1024] copied;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 1 || values[index] > 100000) { return -1; }
        copied[index] = (int)values[index];
    }
    long maximum = 0;
    for (usz index = 0; index < length / 2; index++) {
        long twin_sum = (long)copied[index] + copied[length - index - 1];
        if (twin_sum > maximum) { maximum = twin_sum; }
    }
    return maximum;
}

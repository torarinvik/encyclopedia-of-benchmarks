module find_duplicate_number;

// Find the cycle entrance induced by the duplicate value.
fn long find_duplicate_number(long* values, usz length) @export("find_duplicate_number") {
    if (length < 2 || length > 100001) return -1;
    usz maximum_value = length - 1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 1 || (ulong)values[index] > maximum_value) return -1;
    }

    usz slow = (usz)values[0];
    usz fast = slow;
    do {
        slow = (usz)values[slow];
        fast = (usz)values[(usz)values[fast]];
    } while (slow != fast);

    slow = (usz)values[0];
    while (slow != fast) {
        slow = (usz)values[slow];
        fast = (usz)values[fast];
    }
    return (long)slow;
}

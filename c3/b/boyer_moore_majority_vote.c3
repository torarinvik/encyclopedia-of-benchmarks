module boyer_moore_majority_vote;

// Return a strict majority element, or -1 if none exists.
fn long boyer_moore_majority_vote(long* values, usz length) @export("boyer_moore_majority_vote") {
    if (length == 0 || length > 256 || values == null) return -1;
    long candidate = 0;
    usz balance = 0;
    for (usz index = 0; index < length; index++) {
        if (balance == 0) { candidate = values[index]; }
        if (values[index] == candidate) { balance++; }
        else { balance--; }
    }
    usz occurrences = 0;
    for (usz index = 0; index < length; index++) {
        if (values[index] == candidate) { occurrences++; }
    }
    return occurrences > length / 2 ? candidate : -1;
}

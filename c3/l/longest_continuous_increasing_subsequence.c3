module long_cont_inc_subseq;

const usz MAX_LENGTH = 10000;

// Return the longest strictly increasing contiguous run.
fn long longest_continuous_increasing_subsequence(long* values, usz length)
        @export("longest_continuous_increasing_subsequence") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -1000000 || values[index] > 1000000) return -1;
    }
    if (length == 0) return 0;

    usz current = 1;
    usz best = 1;
    for (usz index = 1; index < length; index++) {
        if (values[index] > values[index - 1]) { current++; }
        else { current = 1; }
        if (current > best) best = current;
    }
    return (long)best;
}

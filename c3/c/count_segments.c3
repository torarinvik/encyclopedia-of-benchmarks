module count_segments;

const MAX_LENGTH = 4096;

// Count transitions from ASCII space to a non-space byte.
fn long count_segments(long* input, usz length) @export("count_segments") {
    if (length > MAX_LENGTH || (length != 0 && input == null)) { return -1; }
    long count = 0;
    bool previous_was_space = true;
    for (usz index = 0; index < length; index++) {
        long value = input[index];
        if (value < 1 || value > 127) { return -1; }
        if (value != 32 && previous_was_space) { count++; }
        previous_was_space = value == 32;
    }
    return count;
}

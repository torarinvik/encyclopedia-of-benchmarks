module dancing_links;

// Count exact covers by indexed row selections and emit each selection mask.
fn long dancing_links(long* input, usz length, char* output, usz output_capacity)
        @export("dancing_links") {
    if (input == null || length < 2) return -1;
    long universe = input[0];
    long row_count = input[1];
    if (universe < 1 || universe > 8 || row_count < 0 || row_count > 8 ||
        length != (usz)(row_count + 2)) return -1;
    long full_mask = (1L << universe) - 1;
    for (usz row = 0; row < (usz)row_count; row++) {
        if (input[row + 2] <= 0 || (input[row + 2] & ~full_mask) != 0) return -1;
    }
    usz selection_limit = (usz)1 << (usz)row_count;
    usz solution_count = 0;
    for (usz selection = 0; selection < selection_limit; selection++) {
        long covered = 0;
        bool valid = true;
        for (usz row = 0; row < (usz)row_count; row++) {
            if ((selection & ((usz)1 << row)) == 0) continue;
            long mask = input[row + 2];
            if ((covered & mask) != 0) { valid = false; break; }
            covered |= mask;
        }
        if (valid && covered == full_mask) solution_count++;
    }
    if (output_capacity < solution_count || (solution_count != 0 && output == null)) return -2;
    usz position = 0;
    for (usz selection = 0; selection < selection_limit; selection++) {
        long covered = 0;
        bool valid = true;
        for (usz row = 0; row < (usz)row_count; row++) {
            if ((selection & ((usz)1 << row)) == 0) continue;
            long mask = input[row + 2];
            if ((covered & mask) != 0) { valid = false; break; }
            covered |= mask;
        }
        if (valid && covered == full_mask) {
            output[position] = (char)selection;
            position++;
        }
    }
    return (long)solution_count;
}

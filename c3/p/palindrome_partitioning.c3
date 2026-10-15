module palindrome_partitioning;

const usz MAX_LENGTH = 256;

fn long palindrome_partitioning(long* input, usz length, char* output, usz output_capacity)
    @export("palindrome_partitioning") {
    if (input == null || length == 0 || length > MAX_LENGTH) return -1;
    for (usz index = 0; index < length; index++)
        if (input[index] < 0 || input[index] > 127) return -1;
    if (output == null || output_capacity < 8) return -2;

    bool[MAX_LENGTH * MAX_LENGTH] palindrome;
    for (usz index = 0; index < MAX_LENGTH * MAX_LENGTH; index++) palindrome[index] = false;
    long[MAX_LENGTH] cuts;
    for (usz end = 0; end < length; end++) {
        long best = (long)end;
        for (usz start = 0; start <= end; start++) {
            if (input[start] == input[end] &&
                (end - start < 2 || palindrome[(start + 1) * MAX_LENGTH + end - 1])) {
                palindrome[start * MAX_LENGTH + end] = true;
                long candidate = start == 0 ? 0 : cuts[start - 1] + 1;
                if (candidate < best) best = candidate;
            }
        }
        cuts[end] = best;
    }

    ulong bits = (ulong)cuts[length - 1];
    for (usz byte = 0; byte < 8; byte++) output[byte] = (char)(bits >> (8 * byte));
    return 1;
}

module plus_one;

// Increment a decimal digit array and write its ASCII representation.
fn long plus_one(long* digits, usz length, char* output, usz output_capacity) @export("plus_one") {
    if (length > 256 || (length != 0 && digits == null)) return -1;
    bool all_nines = true;
    for (usz index = 0; index < length; index++) {
        if (digits[index] < 0 || digits[index] > 9) return -1;
        if (digits[index] != 9) all_nines = false;
    }
    if (length > 1 && digits[0] == 0) return -1;
    usz output_length = length;
    if (length == 0 || all_nines) output_length++;
    if (output_capacity < output_length) return -2;
    if (length == 0 || all_nines) {
        output[0] = '1';
        for (usz index = 1; index < output_length; index++) output[index] = '0';
        return (long)output_length;
    }
    for (usz index = 0; index < length; index++) output[index] = (char)('0' + digits[index]);
    for (usz index = length; index > 0; index--) {
        if (digits[index - 1] == 9) { output[index - 1] = '0'; }
        else {
            output[index - 1]++;
            break;
        }
    }
    return (long)output_length;
}

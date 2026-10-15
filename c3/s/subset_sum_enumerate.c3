module subset_sum_enumerate;

// Emit the index masks of all signed subsets matching the target.
fn long subset_sum_enumerate(long* input, usz length, char* output, usz output_capacity) @export("subset_sum_enumerate")
{
    if (length == 0 || length > 9) return -1;
    long target = input[0];
    if (target < -512 || target > 512) return -1;
    usz items = length - 1;
    for (usz index = 0; index < items; index++) {
        if (input[index + 1] < -64 || input[index + 1] > 64) return -1;
    }
    char[256] masks;
    usz count = 0;
    usz limit = (usz)1 << items;
    for (usz mask = 0; mask < limit; mask++) {
        long sum = 0;
        for (usz index = 0; index < items; index++) {
            if (((mask >> index) & 1) != 0) sum += input[index + 1];
        }
        if (sum == target) {
            masks[count] = (char)mask;
            count++;
        }
    }
    if (output_capacity < count) return -2;
    for (usz index = 0; index < count; index++) output[index] = masks[index];
    return (long)count;
}

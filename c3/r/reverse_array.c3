module reverse_array;

fn long reverse_array(long* input, usz length, char* output, usz capacity) @export("reverse_array") {
    if (length < 1 || length > 257 || input == null) return -1;
    long count = input[0];
    if (count < 1 || count > 256 || length != (usz)(count + 1)) return -1;
    for (usz i = 0; i < (usz)count; i++) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;
    if (capacity < (usz)count || output == null) return -2;
    for (usz i = 0; i < (usz)count; i++) output[i] = (char)input[i + 1];
    usz left = 0, right = (usz)count - 1;
    while (left < right) { char tmp = output[left]; output[left] = output[right]; output[right] = tmp; left++; right--; }
    return count;
}

module reverse_string_in_place;

const usz MAX_LENGTH = 4096;

fn long reverse_string_in_place(long* input, usz length, char* output, usz output_capacity)
        @export("reverse_string_in_place") {
    if (length > MAX_LENGTH || (length != 0 && input == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (input[index] < 0 || input[index] > 255) return -1;
    }
    if (output_capacity < length || (length != 0 && output == null)) return -2;
    for (usz index = 0; index < length; index++) output[index] = (char)(uint)input[index];
    usz left = 0;
    usz right = length;
    while (left < right) {
        right--;
        if (left >= right) break;
        char temporary = output[left];
        output[left] = output[right];
        output[right] = temporary;
        left++;
    }
    return (long)length;
}

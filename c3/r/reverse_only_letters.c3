module reverse_only_letters;

const usz MAX_LENGTH = 4096;

fn bool is_ascii_letter(char value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

fn long reverse_only_letters(long* input, usz length, char* output, usz output_capacity)
        @export("reverse_only_letters") {
    if (length > MAX_LENGTH || (length != 0 && input == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (input[index] < 32 || input[index] > 126) return -1;
    }
    if (output_capacity < length || (length != 0 && output == null)) return -2;
    for (usz index = 0; index < length; index++) output[index] = (char)(uint)input[index];

    usz left = 0;
    usz right = length;
    while (left < right) {
        if (!is_ascii_letter(output[left])) {
            left++;
        } else if (!is_ascii_letter(output[right - 1])) {
            right--;
        } else {
            char temporary = output[left];
            output[left] = output[right - 1];
            output[right - 1] = temporary;
            left++;
            right--;
        }
    }
    return (long)length;
}

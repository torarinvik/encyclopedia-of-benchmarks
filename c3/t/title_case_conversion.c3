module title_case_conversion;

const usz MAX_LENGTH = 256;

// Apply the pinned JavaScript title-case behavior to bounded ASCII words.
fn long title_case_conversion(long* input, usz length, char* output,
                              usz output_capacity) @export("title_case_conversion") {
    if (length == 0 || length > MAX_LENGTH + 1 || input == null) { return -1; }
    long declared = input[0];
    if (declared < 0 || declared > MAX_LENGTH || length != (usz)declared + 1) { return -1; }
    for (usz index = 0; index < (usz)declared; index++) {
        long value = input[index + 1];
        bool letter = (value >= 65 && value <= 90) || (value >= 97 && value <= 122);
        if (!letter && value != 32) { return -1; }
        if (value == 32 && (index == 0 || index + 1 == (usz)declared || input[index] == 32)) { return -1; }
    }
    if (output_capacity < (usz)declared + 1) { return -2; }
    bool at_word_start = true;
    for (usz index = 0; index < (usz)declared; index++) {
        long value = input[index + 1];
        if (value == 32) { at_word_start = true; }
        else if (at_word_start) {
            if (value >= 97 && value <= 122) { value -= 32; }
            at_word_start = false;
        } else if (value >= 65 && value <= 90) { value += 32; }
        output[index] = (char)value;
    }
    output[declared] = 0;
    return declared;
}

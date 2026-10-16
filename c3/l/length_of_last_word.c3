module length_of_last_word;

fn long length_of_last_word(long* input, usz length) @export("length_of_last_word") {
    if (input == null || length < 1 || length > 129) return -1;
    if (input[0] < 0 || input[0] > 128 || length != input[0].usz() + 1) return -1;
    usz index = input[0].usz();
    while (index > 0 && input[index] == 32) index--;
    long word_length = 0;
    while (index > 0 && input[index] != 32) {
        if (input[index] < 0 || input[index] > 255) return -1;
        word_length++;
        index--;
    }
    for (usz i = 1; i < length; i++) if (input[i] < 0 || input[i] > 255) return -1;
    return word_length;
}

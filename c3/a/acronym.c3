module acronym;

const usz MAX_PHRASE_LENGTH = 79;

fn long acronym(long* phrase, usz length, char* output, usz output_capacity)
        @export("acronym") {
    usz required = 0;
    if (length > MAX_PHRASE_LENGTH) return -1;
    for (usz index = 0; index < length; index++) {
        if (phrase[index] < 1 || phrase[index] > 127) return -1;
        if (phrase[index] != 32 && (index == 0 || phrase[index - 1] == 32)) required++;
    }
    if (output_capacity < required) return -2;
    usz written = 0;
    for (usz index = 0; index < length; index++) {
        long value = phrase[index];
        if (value != 32 && (index == 0 || phrase[index - 1] == 32)) {
            if (value >= 97 && value <= 122) value -= 32;
            output[written++] = (char)value;
        }
    }
    return (long)written;
}

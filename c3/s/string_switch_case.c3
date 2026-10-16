module string_switch_case;

const usz MAX_TEXT_LENGTH = 1024;
const usz MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 3;

fn bool is_space(long value) {
    return value == 32 || (value >= 9 && value <= 13) || (value >= 28 && value <= 31);
}
fn bool is_word(long value) {
    return (value >= 65 && value <= 90) || (value >= 97 && value <= 122) ||
           (value >= 48 && value <= 57);
}

fn long string_switch_case(long* input, usz length, char* output, usz capacity) @export("string_switch_case") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long mode = input[0], separator = input[1], text_length = input[2];
    if (mode < 0 || mode > 8 || separator < 0 || separator > 127 || text_length < 0 ||
        text_length > (long)MAX_TEXT_LENGTH || length != (usz)text_length + 3 ||
        ((mode != 3 && mode != 4) && separator != 0)) return -1;
    for (usz i = 0; i < (usz)text_length; i++)
        if (input[i + 3] < 0 || input[i + 3] > 127) return -1;

    char[MAX_TEXT_LENGTH] result;
    usz used = 0;
    if (mode <= 2) {
        bool at_word_start = true;
        for (usz i = 0; i < (usz)text_length; i++) {
            long value = input[i + 3];
            if (!is_word(value)) { at_word_start = true; continue; }
            if (at_word_start) {
                if (value >= 97 && value <= 122) value -= 32;
                at_word_start = false;
            } else if (value >= 65 && value <= 90) value += 32;
            result[used++] = (char)value;
        }
        if (mode == 2) {
            if (used == 0) {
                char[16] empty_message = "not valid string";
                for (usz i = 0; i < 16; i++) result[used++] = empty_message[i];
            } else if (result[0] >= 'A' && result[0] <= 'Z') result[0] += 32;
        }
    } else {
        bool upper = mode == 4 || mode == 6 || mode == 8;
        char delimiter = (char)(mode <= 4 ? separator : mode <= 6 ? 95 : 45);
        bool group_has_word = false, pending_space = false;
        for (usz i = 0; i < (usz)text_length; i++) {
            long value = input[i + 3];
            if (is_space(value)) { if (group_has_word) pending_space = true; continue; }
            if (!is_word(value)) { group_has_word = false; pending_space = false; continue; }
            if (pending_space && group_has_word) result[used++] = delimiter;
            pending_space = false;
            if (upper && value >= 97 && value <= 122) value -= 32;
            else if (!upper && value >= 65 && value <= 90) value += 32;
            result[used++] = (char)value;
            group_has_word = true;
        }
    }
    if (used > capacity || (used > 0 && output == null)) return -2;
    for (usz i = 0; i < used; i++) output[i] = result[i];
    return (long)used;
}

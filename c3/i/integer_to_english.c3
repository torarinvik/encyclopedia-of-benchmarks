module integer_to_english;

fn usz append_text(char* buffer, usz position, const char* text) {
    for (usz index = 0; text[index] != 0; index++) buffer[position++] = text[index];
    return position;
}

fn usz append_word(char* buffer, usz position, const char* text) {
    if (position != 0) buffer[position++] = ' ';
    return append_text(buffer, position, text);
}

fn usz append_small(char* buffer, usz position, long value) {
    switch (value) {
        case 1: return append_word(buffer, position, "One");
        case 2: return append_word(buffer, position, "Two");
        case 3: return append_word(buffer, position, "Three");
        case 4: return append_word(buffer, position, "Four");
        case 5: return append_word(buffer, position, "Five");
        case 6: return append_word(buffer, position, "Six");
        case 7: return append_word(buffer, position, "Seven");
        case 8: return append_word(buffer, position, "Eight");
        case 9: return append_word(buffer, position, "Nine");
        case 10: return append_word(buffer, position, "Ten");
        case 11: return append_word(buffer, position, "Eleven");
        case 12: return append_word(buffer, position, "Twelve");
        case 13: return append_word(buffer, position, "Thirteen");
        case 14: return append_word(buffer, position, "Fourteen");
        case 15: return append_word(buffer, position, "Fifteen");
        case 16: return append_word(buffer, position, "Sixteen");
        case 17: return append_word(buffer, position, "Seventeen");
        case 18: return append_word(buffer, position, "Eighteen");
        case 19: return append_word(buffer, position, "Nineteen");
        case 20: return append_word(buffer, position, "Twenty");
        default: return position;
    }
}

fn usz append_tens(char* buffer, usz position, long value) {
    switch (value) {
        case 2: return append_word(buffer, position, "Twenty");
        case 3: return append_word(buffer, position, "Thirty");
        case 4: return append_word(buffer, position, "Forty");
        case 5: return append_word(buffer, position, "Fifty");
        case 6: return append_word(buffer, position, "Sixty");
        case 7: return append_word(buffer, position, "Seventy");
        case 8: return append_word(buffer, position, "Eighty");
        case 9: return append_word(buffer, position, "Ninety");
        default: return position;
    }
}

fn usz append_group(char* buffer, usz position, long value) {
    if (value >= 100) {
        position = append_small(buffer, position, value / 100);
        position = append_word(buffer, position, "Hundred");
        value %= 100;
    }
    if (value <= 20) return append_small(buffer, position, value);
    position = append_tens(buffer, position, value / 10);
    if (value % 10 != 0) position = append_small(buffer, position, value % 10);
    return position;
}

fn usz append_scale(char* buffer, usz position, usz scale) {
    if (scale == 1) return append_word(buffer, position, "Thousand");
    if (scale == 2) return append_word(buffer, position, "Million");
    if (scale == 3) return append_word(buffer, position, "Billion");
    return position;
}

fn long integer_to_english(long* input, usz length, char* output, usz output_capacity)
        @export("integer_to_english") {
    if (input == null || length != 1 || input[0] < -2147483648 || input[0] > 2147483647) return -1;
    char[128] buffer;
    usz position = 0;
    long value = input[0];
    if (value == 0) {
        position = append_word(&buffer[0], position, "Zero");
    } else if (value > 0) {
        long[4] groups;
        usz count = 0;
        while (value != 0) { groups[count++] = value % 1000; value /= 1000; }
        while (count > 0) {
            count--;
            if (groups[count] != 0) {
                position = append_group(&buffer[0], position, groups[count]);
                if (count != 0) position = append_scale(&buffer[0], position, count);
            }
        }
    }
    if (position > output_capacity || (position != 0 && output == null)) return -2;
    for (usz index = 0; index < position; index++) output[index] = buffer[index];
    return (long)position;
}

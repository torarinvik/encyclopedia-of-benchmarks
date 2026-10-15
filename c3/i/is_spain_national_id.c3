module is_spain_national_id;

const char[23] CHECK_LETTERS = {'T', 'R', 'W', 'A', 'G', 'M', 'Y', 'F', 'P', 'D', 'X', 'B', 'N', 'J', 'Z', 'S', 'Q', 'V', 'H', 'L', 'C', 'K', 'E'};

fn long is_spain_national_id(long* input, usz length) @export("is_spain_national_id") {
    if (input == null || (length != 9 && length != 10)) return -1;
    for (usz index = 0; index < length; index++) {
        if (input[index] < 0 || input[index] > 127) return -1;
    }
    if (length == 10 && input[8] != '-') return -1;
    long number = 0;
    for (usz index = 0; index < 8; index++) {
        if (input[index] < '0' || input[index] > '9') return -1;
        number = number * 10 + input[index] - '0';
    }
    long letter = input[length - 1];
    if (letter >= 'a' && letter <= 'z') letter -= 'a' - 'A';
    if (letter < 'A' || letter > 'Z') return -1;
    return letter == CHECK_LETTERS[(usz)(number % 23)] ? 1 : 0;
}

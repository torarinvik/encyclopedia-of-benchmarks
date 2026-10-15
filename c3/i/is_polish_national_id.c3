module is_polish_national_id;

fn long is_polish_national_id(long* input, usz length) @export("is_polish_national_id") {
    if (input == null || length != 11) return -1;
    long number = 0;
    for (usz index = 0; index < length; index++) {
        if (input[index] < '0' || input[index] > '9') return -1;
        number = number * 10 + input[index] - '0';
    }
    if (number < 10100000 || number > 99923199999) return 0;
    long month = (input[2] - '0') * 10 + input[3] - '0';
    bool valid_month = (month >= 1 && month <= 12) || (month >= 21 && month <= 32) ||
                       (month >= 41 && month <= 52) || (month >= 61 && month <= 72) ||
                       (month >= 81 && month <= 92);
    if (!valid_month) return 0;
    long day = (input[4] - '0') * 10 + input[5] - '0';
    if (day < 1 || day > 31) return 0;
    long[4] weights = {1, 3, 7, 9};
    long subtotal = 0;
    for (usz index = 0; index < 10; index++) {
        subtotal += ((input[index] - '0') * weights[index % 4]) % 10;
    }
    long checksum = 10 - subtotal % 10;
    return checksum == number % 10 ? 1 : 0;
}

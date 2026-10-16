module credit_card_validator;
const usz MAX_TEXT_LENGTH = 64;

fn long credit_card_validator_impl(long* input, usz length) {
    if (input == null || length < 1 || length > MAX_TEXT_LENGTH + 1) return -1;
    long n = input[0];
    if (n < 0 || n > MAX_TEXT_LENGTH || length != (usz)(n + 1)) return -1;
    bool all_digits = true;
    for (usz i = 0; i < (usz)n; i++) {
        long ch = input[i + 1];
        if (ch < 0 || ch > 127) return -1;
        if (ch < 48 || ch > 57) all_digits = false;
    }
    if (!all_digits || n < 13 || n > 16) return 0;
    long first = input[1] - 48;
    long second = input[2] - 48;
    if (!(first == 4 || first == 5 || first == 6 || (first == 3 && (second == 4 || second == 5 || second == 7)))) return 0;
    long sum = 0;
    for (usz i = 0; i < (usz)n; i++) {
        long digit = input[i + 1] - 48;
        if ((long)(i % 2) == n % 2) { digit *= 2; if (digit > 9) digit -= 9; }
        sum += digit;
    }
    return sum % 10 == 0 ? 1 : 0;
}

fn long credit_card_validator(long* input, usz length) @export("credit_card_validator") {
    return credit_card_validator_impl(input, length);
}

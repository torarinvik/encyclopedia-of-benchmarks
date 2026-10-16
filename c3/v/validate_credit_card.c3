module validate_credit_card;

const usz MAX_TEXT_LENGTH = 64;

fn long validate_credit_card(long* input, usz length) @export("validate_credit_card") {
    if (input == null || length < 1 || length > MAX_TEXT_LENGTH + 1) return -1;
    long n = input[0];
    if (n < 0 || n > MAX_TEXT_LENGTH || length != (usz)n + 1) return -1;
    for (usz i = 0; i < (usz)n; i++) {
        if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    }
    if (n < 13 || n > 16) return 0;
    for (usz i = 0; i < (usz)n; i++) {
        if (input[i + 1] < '0' || input[i + 1] > '9') return 0;
    }
    long first = input[1] - '0';
    long second = input[2] - '0';
    if (!(first == 4 || first == 5 || first == 6 ||
          (first == 3 && (second == 4 || second == 5 || second == 7)))) return 0;
    long sum = 0;
    for (usz i = 0; i < (usz)n; i++) {
        long digit = input[i + 1] - '0';
        if (i % 2 == 0) { digit *= 2; if (digit > 9) digit -= 9; }
        sum += digit;
    }
    return sum % 10 == 0 ? 1 : 0;
}

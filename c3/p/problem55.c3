module problem55;

const long MAX_LIMIT = 10000;
const usz MAX_DIGITS = 64;

fn usz reverse_add(u8* digits, usz length) {
    usz reverse_length = length;
    while (reverse_length > 0 && digits[length - reverse_length] == 0) reverse_length--;
    usz combined_length = length > reverse_length ? length : reverse_length;
    u8[MAX_DIGITS] next = {0};
    int carry = 0;
    for (usz position = 0; position < combined_length; position++) {
        int left = position < length ? (int)digits[position] : 0;
        int right = position < reverse_length ? (int)digits[length - 1 - position] : 0;
        int sum = left + right + carry;
        next[position] = (u8)(sum % 10);
        carry = sum / 10;
    }
    usz next_length = combined_length;
    if (carry > 0) next[next_length++] = (u8)carry;
    for (usz index = 0; index < next_length; index++) digits[index] = next[index];
    return next_length;
}

fn bool is_palindrome(u8* digits, usz length) {
    for (usz left = 0; left < length / 2; left++) {
        if (digits[left] != digits[length - 1 - left]) return false;
    }
    return true;
}

fn long problem55(long limit) @export("problem55") {
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    long count = 0;
    for (long start = 1; start < limit; start++) {
        u8[MAX_DIGITS] digits = {0};
        usz length = 0;
        ulong value = (ulong)start;
        while (value > 0) {
            digits[length++] = (u8)(value % 10);
            value /= 10;
        }
        bool became_palindrome = false;
        for (int iteration = 0; iteration < 50; iteration++) {
            length = reverse_add(&digits[0], length);
            if (is_palindrome(&digits[0], length)) {
                became_palindrome = true;
                break;
            }
        }
        if (!became_palindrome) count++;
    }
    return count;
}

module addition_of_big_integers;

fn long addition_of_big_integers(long* input, usz length, char* output, usz capacity)
    @export("addition_of_big_integers") {
    if (input == null || length < 4 || length > 68) return -1;
    long raw_a = input[0], raw_b = input[1];
    if (raw_a < 1 || raw_a > 33 || raw_b < 1 || raw_b > 33) return -1;
    usz len_a = (usz)raw_a, len_b = (usz)raw_b;
    if (length != 2 + len_a + len_b) return -1;

    usz starts[2];
    usz counts[2];
    bool negatives[2];
    starts[0] = 2;
    starts[1] = 2 + len_a;
    usz lengths[2];
    lengths[0] = len_a;
    lengths[1] = len_b;
    for (usz operand = 0; operand < 2; operand++) {
        if (lengths[operand] < 1 || lengths[operand] > 33) return -1;
        negatives[operand] = input[starts[operand]] == 45;
        if (negatives[operand]) {
            starts[operand]++;
            counts[operand] = lengths[operand] - 1;
        } else {
            counts[operand] = lengths[operand];
        }
        if (counts[operand] < 1 || counts[operand] > 32) return -1;
        for (usz i = 0; i < counts[operand]; i++) {
            long byte = input[starts[operand] + i];
            if (byte < 48 || byte > 57 || (i == 0 && counts[operand] > 1 && byte == 48)) return -1;
        }
        if (negatives[operand] && counts[operand] == 1 && input[starts[operand]] == 48) return -1;
    }

    long reversed[33];
    for (usz i = 0; i < 33; i++) reversed[i] = 0;
    usz digits = 0;
    bool negative = false;
    if (negatives[0] == negatives[1]) {
        negative = negatives[0];
        usz width = counts[0] > counts[1] ? counts[0] : counts[1];
        long carry = 0;
        for (usz offset = 0; offset < width; offset++) {
            long da = offset < counts[0] ? input[starts[0] + counts[0] - 1 - offset] - 48 : 0;
            long db = offset < counts[1] ? input[starts[1] + counts[1] - 1 - offset] - 48 : 0;
            long total = da + db + carry;
            reversed[digits++] = total % 10;
            carry = total / 10;
        }
        if (carry != 0) reversed[digits++] = carry;
    } else {
        int order = 0;
        if (counts[0] != counts[1]) order = counts[0] > counts[1] ? 1 : -1;
        else for (usz i = 0; i < counts[0] && order == 0; i++) {
            long da = input[starts[0] + i], db = input[starts[1] + i];
            if (da != db) order = da > db ? 1 : -1;
        }
        if (order == 0) {
            reversed[0] = 0;
            digits = 1;
        } else {
            usz big, small;
            if (order > 0) { big = 0; small = 1; }
            else { big = 1; small = 0; }
            negative = negatives[big];
            long borrow = 0;
            for (usz offset = 0; offset < counts[big]; offset++) {
                long da = input[starts[big] + counts[big] - 1 - offset] - 48;
                long db = offset < counts[small] ? input[starts[small] + counts[small] - 1 - offset] - 48 : 0;
                long digit = da - db - borrow;
                borrow = digit < 0 ? 1 : 0;
                reversed[digits++] = digit < 0 ? digit + 10 : digit;
            }
            while (digits > 1 && reversed[digits - 1] == 0) digits--;
        }
    }
    usz output_length = digits + (negative ? 1 : 0);
    if (output == null || capacity < output_length) return -2;
    usz cursor = 0;
    if (negative) output[cursor++] = '-';
    for (usz i = 0; i < digits; i++) output[cursor++] = (char)('0' + reversed[digits - 1 - i]);
    return (long)output_length;
}

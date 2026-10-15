module reverse_integer;

const INVALID_RESULT = -2147483649L;

// Reverse a signed 32-bit decimal integer, returning zero on overflow.
fn long reverse_integer(long input) @export("reverse_integer") {
    if (input < -2147483648 || input > 2147483647) { return INVALID_RESULT; }
    long reversed = 0;
    while (input != 0) {
        long digit = input % 10;
        input /= 10;
        if (reversed > 214748364 || (reversed == 214748364 && digit > 7)) { return 0; }
        if (reversed < -214748364 || (reversed == -214748364 && digit < -8)) { return 0; }
        reversed = reversed * 10 + digit;
    }
    return reversed;
}

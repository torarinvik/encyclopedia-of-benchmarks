module problem24;

fn long problem24(long ignored) @export("problem24") {
    if (ignored != 0) return -1;
    long rank = 999999;
    long factorial = 362880;
    long used = 0;
    long result = 0;
    for (long slots = 10; slots > 0; slots--) {
        long choice = rank / factorial;
        rank %= factorial;
        long selected = -1;
        for (long digit = 0; digit < 10; digit++) {
            long bit = 1L << digit;
            if ((used & bit) != 0) continue;
            if (choice == 0) {
                selected = digit;
                used |= bit;
                break;
            }
            choice--;
        }
        result = result * 10 + selected;
        if (slots > 1) factorial /= slots - 1;
    }
    return result;
}

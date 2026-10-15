module kaprekar_number;

fn long kaprekar_number(long number) @export("kaprekar_number") {
    if (number < 1) return 0;
    if (number > 2000000000) return -1;
    if (number == 1) return 1;
    long square = number * number;
    long split = 10;
    while (split <= square) {
        long right = square % split;
        if (right > 0 && square / split + right == number) return 1;
        if (split > square / 10) break;
        split *= 10;
    }
    return 0;
}

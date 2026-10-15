module trimorphic_number;

fn long trimorphic_number(long number) @export("trimorphic_number") {
    if (number < 0 || number > 2000000) return -1;
    long modulus = 10;
    long digits = number;
    while (digits >= 10) {
        digits /= 10;
        modulus *= 10;
    }
    long cube = number * number * number;
    return cube % modulus == number ? 1 : 0;
}

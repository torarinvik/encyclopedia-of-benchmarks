module problem3;

fn long problem3(long number) @export("problem3") {
    if (number < 2 || number > 600851475143) return -1;
    long remaining = number;
    long largest = 1;
    long factor = 2;
    while (factor <= remaining / factor) {
        if (remaining % factor == 0) {
            largest = factor;
            remaining /= factor;
        } else {
            factor++;
        }
    }
    return remaining > 1 ? remaining : largest;
}

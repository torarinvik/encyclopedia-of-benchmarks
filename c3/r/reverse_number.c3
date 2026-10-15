module reverse_number;

const long MAX_INPUT = 1000000000;

fn long reverse_number(long number) @export("reverse_number") {
    if (number < 0 || number > MAX_INPUT) return -1;
    long reversed = 0;
    while (number > 0) {
        reversed = reversed * 10 + number % 10;
        number /= 10;
    }
    return reversed;
}

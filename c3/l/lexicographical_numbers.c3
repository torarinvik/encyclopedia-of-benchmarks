module lexicographical_numbers;

const long MAX_NUMBER = 4096;
const usz STACK_CAPACITY = 4112;

fn long lexicographical_numbers(long* values, usz length) @export("lexicographical_numbers") {
    if (values == null || length != 1 || values[0] < 0 || values[0] > MAX_NUMBER) return -1;
    long[STACK_CAPACITY] stack;
    usz top = 1; stack[0] = 1;
    long index = 0, checksum = 0;
    while (top > 0) {
        top--; long number = stack[top];
        if (number <= values[0]) {
            index++; checksum += index * number;
            if (number % 10 != 9) { stack[top] = number + 1; top++; }
            stack[top] = number * 10; top++;
        }
    }
    return checksum;
}

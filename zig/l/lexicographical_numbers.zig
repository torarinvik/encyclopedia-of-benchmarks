const MAX_NUMBER: i64 = 4096;
const STACK_CAPACITY: usize = 4112;

export fn lexicographical_numbers(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 1 or values[0] < 0 or values[0] > MAX_NUMBER) return -1;
    var stack: [STACK_CAPACITY]i64 = @splat(0);
    var top: usize = 1;
    stack[0] = 1;
    var index: i64 = 0;
    var checksum: i64 = 0;
    while (top > 0) {
        top -= 1;
        const number = stack[top];
        if (number <= values[0]) {
            index += 1;
            checksum += index * number;
            if (@mod(number, 10) != 9) { stack[top] = number + 1; top += 1; }
            stack[top] = number * 10;
            top += 1;
        }
    }
    return checksum;
}

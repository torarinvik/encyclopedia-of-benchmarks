module single_bit_manipulation_operations;

fn long single_bit_manipulation_operations(long* input, usz length) @export("single_bit_manipulation_operations") {
    if (input == null || length != 3) return -1;
    long opcode = input[0], number = input[1], position = input[2];
    if (opcode < 0 || opcode > 5 || number < -2147483648 || number > 2147483647) return -1;
    if (opcode == 5) {
        if (position != -1) return -1;
        return number & (number - 1);
    }
    if (position < 0 || position > 31) return -1;
    long mask = (long)1 << position;
    switch (opcode) {
        case 0: return number | mask;
        case 1: return number & ~mask;
        case 2: return number ^ mask;
        case 3: return (long)((@bitcast(ulong, number) >> (usz)position) & 1);
        case 4: return (number & mask) != 0 ? 1 : 0;
        default: return -1;
    }
}

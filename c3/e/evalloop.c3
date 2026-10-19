module evalloop;

const long MIN_PASSES = 0;
const long MAX_PASSES = 1000;
const usz BUFFER_SIZE = 2048;
const usz OUTPUT_CAPACITY = 14;

void execute(uint* sum, int opcode) { *sum += (uint)opcode; }

void eval(int* commands, uint* sum) {
    usz pc = 0;
    int opcode = commands[pc++];
    while (opcode != 0) {
        if (opcode >= 1 && opcode <= 31) execute(sum, opcode);
        else return;
        opcode = commands[pc++];
    }
}

usz format_output(uint sum, char* staged) {
    const char* prefix = "Sum: ";
    usz used = 0;
    while (prefix[used] != 0) { staged[used] = prefix[used]; used++; }
    char[10] reversed;
    usz digits = 0;
    do {
        reversed[digits++] = (char)('0' + sum % 10);
        sum /= 10;
    } while (sum != 0);
    while (digits > 0) { digits--; staged[used++] = reversed[digits]; }
    staged[used++] = '\n';
    return used;
}

fn long evalloop(long passes, char* output, usz output_capacity) @export("evalloop") {
    if (passes < MIN_PASSES || passes > MAX_PASSES) return -1;
    if (output == null) return -2;

    int[BUFFER_SIZE] commands;
    for (usz index = 0; index < BUFFER_SIZE - 1; index++) commands[index] = (int)(index % 31 + 1);
    commands[BUFFER_SIZE - 1] = 0;
    uint sum = 0;
    for (long pass = 0; pass < passes; pass++) eval(&commands[0], &sum);

    char[OUTPUT_CAPACITY] staged;
    usz used = format_output(sum, &staged[0]);
    if (output_capacity < used) return -2;
    for (usz index = 0; index < used; index++) output[index] = staged[index];
    return (long)used;
}

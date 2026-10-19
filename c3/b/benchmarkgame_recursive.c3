module benchmarkgame_recursive;

const long MAX_N = 10;
const usz MAX_OUTPUT_BYTES = 89;

fn long ackermann_value(long x, long y) {
    if (x == 0) return y + 1;
    return ackermann_value(x - 1, y == 0 ? 1 : ackermann_value(x, y - 1));
}

fn long fibonacci_integer(long n) {
    if (n < 2) return 1;
    return fibonacci_integer(n - 2) + fibonacci_integer(n - 1);
}

fn double fibonacci_float(double n) {
    if (n < 2.0) return 1.0;
    return fibonacci_float(n - 2.0) + fibonacci_float(n - 1.0);
}

fn long takeuchi_integer(long x, long y, long z) {
    if (y < x)
        return takeuchi_integer(takeuchi_integer(x - 1, y, z),
                                takeuchi_integer(y - 1, z, x),
                                takeuchi_integer(z - 1, x, y));
    return z;
}

fn double takeuchi_float(double x, double y, double z) {
    if (y < x)
        return takeuchi_float(takeuchi_float(x - 1.0, y, z),
                              takeuchi_float(y - 1.0, z, x),
                              takeuchi_float(z - 1.0, x, y));
    return z;
}

fn void append_text(char* buffer, usz* used, char* text) {
    while (*text != 0) buffer[(*used)++] = *text++;
}

fn void append_number(char* buffer, usz* used, long value) {
    char[20] reversed;
    usz count = 0;
    do {
        reversed[count++] = (char)('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (count > 0) buffer[(*used)++] = reversed[--count];
}

fn long benchmarkgame_recursive(long n, char* output, usz output_capacity)
    @export("benchmarkgame_recursive") {
    if (n < 0 || n > MAX_N) return -1;
    if (output == null) return -2;

    char[MAX_OUTPUT_BYTES] staged;
    usz used = 0;
    append_text(staged, &used, "Ack(3,");
    append_number(staged, &used, n + 1);
    append_text(staged, &used, "): ");
    append_number(staged, &used, ackermann_value(3, n + 1));
    append_text(staged, &used, "\nFib(");
    append_number(staged, &used, 28 + n);
    append_text(staged, &used, ".0): ");
    append_number(staged, &used, (long)fibonacci_float((double)(28 + n)));
    append_text(staged, &used, ".0\nTak(");
    append_number(staged, &used, 3 * n);
    append_text(staged, &used, ",");
    append_number(staged, &used, 2 * n);
    append_text(staged, &used, ",");
    append_number(staged, &used, n);
    append_text(staged, &used, "): ");
    append_number(staged, &used, takeuchi_integer(3 * n, 2 * n, n));
    append_text(staged, &used, "\nFib(3): ");
    append_number(staged, &used, fibonacci_integer(3));
    append_text(staged, &used, "\nTak(3.0,2.0,1.0): ");
    append_number(staged, &used, (long)takeuchi_float(3.0, 2.0, 1.0));
    append_text(staged, &used, ".0\n");

    if (output_capacity < used) return -2;
    for (usz index = 0; index < used; index++) output[index] = staged[index];
    return (long)used;
}

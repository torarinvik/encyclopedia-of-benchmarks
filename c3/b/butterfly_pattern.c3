module butterfly_pattern;

fn usz write_run(char* output, usz position, char byte, usz count) {
    for (usz index = 0; index < count; index++) output[position++] = byte;
    return position;
}

fn long butterfly_pattern(long n, char* output, usz capacity) @export("butterfly_pattern") {
    if (n < 1 || n > 45) return -1;
    usz side = (usz)n;
    usz width = 2 * side - 1;
    usz required = width * width + 2 * side - 2;
    if (output == null || capacity < required) return -2;

    usz position = 0;
    for (usz count = 1; count < side; count++) {
        if (position != 0) output[position++] = '\n';
        position = write_run(output, position, '*', count);
        position = write_run(output, position, ' ', 2 * (side - count) - 1);
        position = write_run(output, position, '*', count);
    }
    if (position != 0) output[position++] = '\n';
    position = write_run(output, position, '*', width);
    for (usz count = side - 1; count > 0; count--) {
        output[position++] = '\n';
        position = write_run(output, position, '*', count);
        position = write_run(output, position, ' ', 2 * (side - count) - 1);
        position = write_run(output, position, '*', count);
    }
    return (long)position;
}

module kaprekar_constant;

fn long kaprekar_step(long number) {
    long d0 = number / 1000;
    long d1 = (number / 100) % 10;
    long d2 = (number / 10) % 10;
    long d3 = number % 10;
    long temp = 0;

    if (d0 > d1) { temp = d0; d0 = d1; d1 = temp; }
    if (d2 > d3) { temp = d2; d2 = d3; d3 = temp; }
    if (d0 > d2) { temp = d0; d0 = d2; d2 = temp; }
    if (d1 > d3) { temp = d1; d1 = d3; d3 = temp; }
    if (d1 > d2) { temp = d1; d1 = d2; d2 = temp; }

    long ascending = d0 * 1000 + d1 * 100 + d2 * 10 + d3;
    long descending = d3 * 1000 + d2 * 100 + d1 * 10 + d0;
    return descending - ascending;
}

fn long kaprekar_constant(long* values, usz length) @export("kaprekar_constant") {
    if (values == null || length != 2) return -1;
    long number = values[0];
    long max_iterations = values[1];
    if (number < 0 || number > 9999 || max_iterations < 1 || max_iterations > 16) return -1;
    if (number == 6174) return 0;

    long current = number;
    long iteration = 1;
    while (iteration <= max_iterations) {
        current = kaprekar_step(current);
        if (current == 6174) return iteration;
        if (current == 0) return -1;
        iteration++;
    }
    return -1;
}

module simplest_radical_form;

fn void put64(char* output, usz offset, long value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long simplest_radical_form(long* values, usz length, char* output, usz capacity) @export("simplest_radical_form") {
    if (values == null || length != 1) return -1;
    long original = values[0];
    if (original < 0 || original > 100000000) return -1;
    if (output == null || capacity < 16) return -2;

    long coefficient = 1, root_term = 1;
    if (original == 0) {
        root_term = 0;
    } else {
        long remainder = original;
        for (long factor = 2; factor * factor <= original; factor++) {
            long count = 0;
            while (remainder % factor == 0) { remainder /= factor; count++; }
            for (long power = 0; power < count / 2; power++) coefficient *= factor;
            if (count % 2 != 0) root_term *= factor;
        }
        root_term *= remainder;
    }
    put64(output, 0, coefficient);
    put64(output, 8, root_term);
    return 16;
}

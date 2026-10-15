module nth_ugly_number;

// Return the zero-based 5-smooth number at index n.
fn long nth_ugly_number(long n) @export("nth_ugly_number") {
    if (n < 0 || n > 12690) return -1;

    long values[12691];
    values[0] = 1;
    usz i2 = 0, i3 = 0, i5 = 0;
    for (usz index = 1; index <= (usz)n; index++) {
        long c2 = 2 * values[i2];
        long c3 = 3 * values[i3];
        long c5 = 5 * values[i5];
        long next = c2 < c3 ? c2 : c3;
        if (c5 < next) next = c5;
        values[index] = next;
        if (c2 == next) i2++;
        if (c3 == next) i3++;
        if (c5 == next) i5++;
    }
    return values[(usz)n];
}

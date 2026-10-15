module tetranacci_numbers_sequence;

fn long tetranacci_numbers_sequence(long index) @export("tetranacci_numbers_sequence") {
    if (index < 0 || index > 68) return -1;
    long a = 1;
    long b = 1;
    long c = 1;
    long d = 1;
    if (index <= 3) return 1;
    for (long i = 4; i <= index; i += 1) {
        long next = a + b + c + d;
        a = b;
        b = c;
        c = d;
        d = next;
    }
    return d;
}

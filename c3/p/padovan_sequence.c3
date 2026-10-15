module padovan_sequence;

fn long padovan_sequence(long index) @export("padovan_sequence")
{
    if (index < 0 || index > 156) return -1;
    if (index <= 2) return 1;

    long a = 1;
    long b = 1;
    long c = 1;
    long result = 0;
    for (long i = 3; i <= index; i += 1) {
        result = a + b;
        a = b;
        b = c;
        c = result;
    }
    return result;
}

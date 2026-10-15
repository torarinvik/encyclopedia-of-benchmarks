module perrin_number;

fn long perrin_number(long index) @export("perrin_number")
{
    if (index < 0 || index > 155) return -1;
    if (index == 0) return 3;
    if (index == 1) return 0;
    if (index == 2) return 2;
    long a = 3, b = 0, c = 2;
    long result = 0;
    for (long i = 3; i <= index; i += 1) {
        result = a + b;
        a = b;
        b = c;
        c = result;
    }
    return result;
}

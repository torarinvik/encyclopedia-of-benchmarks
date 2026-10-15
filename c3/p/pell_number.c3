module pell_number;

fn long pell_number(long index) @export("pell_number")
{
    if (index < 0 || index > 50) return -1;
    if (index == 0) return 0;
    long previous = 0;
    long current = 1;
    for (long i = 2; i <= index; i += 1) {
        long next = 2 * current + previous;
        previous = current;
        current = next;
    }
    return current;
}

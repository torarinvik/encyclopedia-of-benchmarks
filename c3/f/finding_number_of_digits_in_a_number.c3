module finding_number_of_digits_in_a_number;

fn long finding_number_of_digits_in_a_number(long value) @export("finding_number_of_digits_in_a_number")
{
    if (value < 0) return -1;
    ulong remaining = (ulong)value;
    long count = 0;
    while (remaining != 0) {
        remaining = remaining / 10;
        count += 1;
    }
    return count;
}

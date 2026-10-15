module fermat_numbers_sequence;

fn long fermat_numbers_sequence(long index) @export("fermat_numbers_sequence")
{
    if (index < 0 || index > 5) return -1;
    long value = 2;
    for (long i = 0; i < index; i += 1) value *= value;
    return value + 1;
}

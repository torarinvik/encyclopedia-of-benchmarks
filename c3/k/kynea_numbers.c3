module kynea_numbers;

fn long kynea_numbers(long index) @export("kynea_numbers")
{
    if (index < 1 || index > 31) return -1;
    long value = (1L << index) + 1;
    long square = value * value;
    return square - 2;
}

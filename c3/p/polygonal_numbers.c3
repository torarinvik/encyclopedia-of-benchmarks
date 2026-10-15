module polygonal_numbers;

fn long polygonal_numbers(long* packed, usz length) @export("polygonal_numbers")
{
    if (length != 2) return -1;
    long num = packed[0];
    long sides = packed[1];
    if (num < 0 || num > 100000000 || sides < 3 || sides > 64) return -1;
    long square = num * num;
    long leading = (sides - 2) * square;
    long trailing = (sides - 4) * num;
    return (leading - trailing) / 2;
}

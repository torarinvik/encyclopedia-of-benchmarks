module vampire_number;

fn uint decimal_length(ulong value)
{
    uint length = 0;
    while (true) {
        length++;
        value /= 10;
        if (value == 0) break;
    }
    return length;
}

fn long vampire_number(ulong left, ulong right) @export("vampire_number")
{
    if (left < 1 || left > 9999 || right < 1 || right > 9999) return -1;
    if (decimal_length(left) != decimal_length(right)) return 0;
    int[10] counts = {0};
    ulong product = left * right;
    while (product != 0) { counts[(usz)(product % 10)]++; product /= 10; }
    while (left != 0) { counts[(usz)(left % 10)]--; left /= 10; }
    while (right != 0) { counts[(usz)(right % 10)]--; right /= 10; }
    for (usz digit = 0; digit < 10; digit++) if (counts[digit] != 0) return 0;
    return 1;
}

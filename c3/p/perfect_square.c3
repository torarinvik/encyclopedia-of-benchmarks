module perfect_square;

// Exact perfect-square check using bounded integer binary search.
fn long perfect_square(long input) @export("perfect_square")
{
    if (input < 0) return 0;
    if (input < 2) return 1;
    ulong number = (ulong)input;
    if (((0x0213UL >> (number & 15)) & 1) == 0) return 0;
    ulong low = 1;
    ulong root_limit = number <= 0xffffffffUL ? 65535 : 3037000499;
    ulong high = number / 2 < root_limit ? number / 2 : root_limit;
    while (low <= high) {
        ulong middle = (low + high) >> 1;
        ulong square = middle * middle;
        if (square == number) return 1;
        if (square < number) {
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    return 0;
}

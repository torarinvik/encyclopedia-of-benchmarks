module perfect_square;

// Exact perfect-square check using integer binary search and division.
fn long perfect_square(long input) @export("perfect_square")
{
    if (input < 0) return 0;
    if (input < 2) return 1;
    ulong number = (ulong)input;
    ulong low = 1;
    ulong high = number / 2;
    while (low <= high) {
        ulong middle = low + (high - low) / 2;
        ulong quotient = number / middle;
        if (quotient == middle) {
            if (number % middle == 0) return 1;
            low = middle + 1;
        } else if (quotient < middle) {
            high = middle - 1;
        } else {
            low = middle + 1;
        }
    }
    return 0;
}

module central_polygonal_numbers_sequence;

// Compute the central polygonal number n(n+1)/2 + 1 safely.
fn long central_polygonal_numbers_sequence(long input) @export("central_polygonal_numbers_sequence")
{
    if (input < 0 || input > 4294967295) return -1;
    long left = input % 2 == 0 ? input / 2 : input;
    long right = input % 2 == 0 ? input + 1 : (input + 1) / 2;
    return left * right + 1;
}

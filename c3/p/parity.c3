module parity;

// Return the parity of the set-bit count using Kernighan's bit clearing.
fn long parity(long number) @export("parity") {
    if (number < 0) return -1;
    long result = 0;
    while (number != 0) {
        result = result ^ 1;
        number = number & (number - 1);
    }
    return result;
}

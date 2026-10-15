module hexagonal_number;

fn long hexagonal_number(long number) @export("hexagonal_number") {
    if (number < 1 || number > 67108864) return -1;
    return number * (2 * number - 1);
}

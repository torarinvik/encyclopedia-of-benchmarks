module problem94;

const long MAX_PERIMETER = 1000000000;

fn long problem94(long max_perimeter) @export("problem94") {
    if (max_perimeter < 0 || max_perimeter > MAX_PERIMETER) return -1;
    long previous = 1, value = 2, perimeter_sum = 0, index = 0, perimeter = 0;
    while (perimeter <= max_perimeter) {
        perimeter_sum += perimeter;
        previous += 2 * value;
        value += previous;
        perimeter = index % 2 == 0 ? 2 * value + 2 : 2 * value - 2;
        index++;
    }
    return perimeter_sum;
}

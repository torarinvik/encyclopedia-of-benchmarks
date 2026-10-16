module problem32;

fn bool next_permutation(long* digits) {
    long pivot = 7;
    while (pivot >= 0 && digits[(usz)pivot] >= digits[(usz)(pivot + 1)]) pivot--;
    if (pivot < 0) return false;
    long successor = 8;
    while (digits[(usz)successor] <= digits[(usz)pivot]) successor--;
    long temporary = digits[(usz)pivot];
    digits[(usz)pivot] = digits[(usz)successor];
    digits[(usz)successor] = temporary;
    long left = pivot + 1;
    long right = 8;
    while (left < right) {
        temporary = digits[(usz)left];
        digits[(usz)left] = digits[(usz)right];
        digits[(usz)right] = temporary;
        left++;
        right--;
    }
    return true;
}

fn long problem32(long ignored) @export("problem32") {
    if (ignored != 0) return -1;
    long[9] digits = {1, 2, 3, 4, 5, 6, 7, 8, 9};
    bool[10000] seen;
    for (usz value = 0; value < 10000; value++) seen[value] = false;
    bool more = true;
    long sum = 0;
    while (more) {
        long product = digits[5] * 1000 + digits[6] * 100 + digits[7] * 10 + digits[8];
        long two_digit = digits[0] * 10 + digits[1];
        long three_digit = digits[2] * 100 + digits[3] * 10 + digits[4];
        long four_digit = digits[1] * 1000 + digits[2] * 100 + digits[3] * 10 + digits[4];
        if (two_digit * three_digit == product || digits[0] * four_digit == product) {
            if (!seen[(usz)product]) {
                seen[(usz)product] = true;
                sum += product;
            }
        }
        more = next_permutation(&digits[0]);
    }
    return sum;
}

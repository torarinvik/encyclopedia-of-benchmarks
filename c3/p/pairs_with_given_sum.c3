module pairs_with_given_sum;

fn long pairs_with_given_sum(long* input, usz length) @export("pairs_with_given_sum") {
    if (input == null || length == 0 || length > 257) return -2;
    for (usz index = 0; index < length; index++) {
        if (input[index] < -2147483648 || input[index] > 2147483647) return -2;
    }
    long target = input[0];
    usz value_count = length - 1;
    long pairs = 0;
    for (usz left = 0; left < value_count; left++) {
        for (usz right = left + 1; right < value_count; right++) {
            if (input[left + 1] + input[right + 1] == target) pairs++;
        }
    }
    return pairs;
}

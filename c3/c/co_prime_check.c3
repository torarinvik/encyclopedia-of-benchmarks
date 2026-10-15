module co_prime_check;

fn long co_prime_check(ulong first, ulong second) @export("co_prime_check") {
    if (first > 2147483647 || second > 2147483647) return -1;
    while (second != 0) {
        ulong remainder = first % second;
        first = second;
        second = remainder;
    }
    return first == 1 ? 1 : 0;
}

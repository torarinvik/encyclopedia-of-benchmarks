module problem10;

fn long problem10(long limit) @export("problem10") {
    if (limit < 0 || limit > 2000000) return -1;
    bool[1000000] composite = {0};
    long odd_count = limit / 2;
    long sum = limit > 2 ? 2 : 0;
    for (long prime = 3; prime * prime < limit; prime += 2) {
        if (!composite[prime / 2]) {
            for (long index = prime * prime / 2; index < odd_count; index += prime) {
                composite[index] = true;
            }
        }
    }
    for (long index = 1; index < odd_count; index++) {
        if (!composite[index]) sum += 2 * index + 1;
    }
    return sum;
}

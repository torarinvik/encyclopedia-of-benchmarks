module problem72;

fn long problem72(long limit) @export("problem72") {
    if (limit < 0 || limit > 1000000) return -1;
    if (limit < 2) return 0;
    u32[1000001] phi = {0};
    if (limit >= 1) phi[1] = 1;
    for (long value = 2; value <= limit; value++) phi[value] = (u32)value;
    for (long prime = 2; prime <= limit; prime++) {
        if (phi[prime] == (u32)prime) {
            for (long multiple = prime; multiple <= limit; multiple += prime)
                phi[multiple] -= phi[multiple] / (u32)prime;
        }
    }
    long total = 0;
    for (long denominator = 2; denominator <= limit; denominator++) total += (long)phi[denominator];
    return total;
}

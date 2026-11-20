module frobenius_number_apery;

const usz MAX_PARSEABLE_LENGTH = 6;
const long MAX_DENOMINATIONS = 4;
const long MAX_DENOMINATION = 16;
const long DISTANCE_INF = 1000000;

fn long gcd_i64(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long apery_frobenius(long* coins, long count, long modulus) {
    long[16] distance;
    bool[16] settled;
    for (int i = 0; i < 16; i++) { distance[i] = DISTANCE_INF; settled[i] = false; }
    distance[0] = 0;
    for (long step = 0; step < modulus; step++) {
        long source = -1;
        long best = DISTANCE_INF;
        for (long residue = 0; residue < modulus; residue++) {
            if (!settled[residue] && distance[residue] < best) { source = residue; best = distance[residue]; }
        }
        if (source < 0) return -1;
        settled[source] = true;
        for (long index = 0; index < count; index++) {
            long coin = coins[index];
            long target = (source + coin) % modulus;
            long candidate = best + coin;
            if (candidate < distance[target]) distance[target] = candidate;
        }
    }
    long maximum = 0;
    for (long residue = 0; residue < modulus; residue++) if (distance[residue] > maximum) maximum = distance[residue];
    return maximum - modulus;
}

fn long frobenius_number_apery(long* input, usz length) @export("frobenius_number_apery") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    long count = input[0];
    if (count < 2 || count > MAX_DENOMINATIONS || length != (usz)(count + 1)) return -1;
    long common = 0;
    long minimum = MAX_DENOMINATION + 1;
    for (long index = 0; index < count; index++) {
        long coin = input[index + 1];
        if (coin < 2 || coin > MAX_DENOMINATION) return -1;
        for (long previous = 0; previous < index; previous++) if (coin == input[previous + 1]) return -1;
        common = gcd_i64(common, coin);
        if (coin < minimum) minimum = coin;
    }
    if (common != 1) return -1;
    return apery_frobenius(input + 1, count, minimum);
}

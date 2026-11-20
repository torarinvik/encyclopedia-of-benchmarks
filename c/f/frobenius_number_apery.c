#include <limits.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_PARSEABLE_LENGTH = 6, MAX_DENOMINATIONS = 4, MAX_DENOMINATION = 16 };
static const int64_t DISTANCE_INF = INT64_C(1000000);

static int64_t gcd_i64(int64_t left, int64_t right) {
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static int64_t apery_frobenius(const int64_t *coins, int64_t count, int64_t modulus) {
    int64_t distance[16];
    uint8_t settled[16] = {0};
    for (int64_t residue = 0; residue < modulus; ++residue) distance[residue] = DISTANCE_INF;
    distance[0] = 0;
    for (int64_t step = 0; step < modulus; ++step) {
        int64_t source = -1;
        int64_t best = DISTANCE_INF;
        for (int64_t residue = 0; residue < modulus; ++residue) {
            if (!settled[residue] && distance[residue] < best) {
                source = residue;
                best = distance[residue];
            }
        }
        if (source < 0) return -1;
        settled[source] = 1;
        for (int64_t index = 0; index < count; ++index) {
            const int64_t coin = coins[index];
            const int64_t target = (source + coin) % modulus;
            const int64_t candidate = best + coin;
            if (candidate < distance[target]) distance[target] = candidate;
        }
    }
    int64_t maximum = 0;
    for (int64_t residue = 0; residue < modulus; ++residue) {
        if (distance[residue] > maximum) maximum = distance[residue];
    }
    return maximum - modulus;
}

int64_t frobenius_number_apery(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t count = input[0];
    if (count < 2 || count > MAX_DENOMINATIONS || length != (size_t)(count + 1)) return -1;
    int64_t common = 0;
    int64_t minimum = MAX_DENOMINATION + 1;
    for (int64_t index = 0; index < count; ++index) {
        const int64_t coin = input[index + 1];
        if (coin < 2 || coin > MAX_DENOMINATION) return -1;
        for (int64_t previous = 0; previous < index; ++previous) {
            if (coin == input[previous + 1]) return -1;
        }
        common = gcd_i64(common, coin);
        if (coin < minimum) minimum = coin;
    }
    if (common != 1) return -1;
    return apery_frobenius(input + 1, count, minimum);
}

module coin_change;

// Return the minimum number of unlimited coins needed to reach an amount.
fn long coin_change(long* packed, usz length) @export("coin_change")
{
    if (packed == null || length < 2 || length > 130) return -1;
    long amount = packed[0];
    long coin_count = packed[1];
    if (amount < 0 || amount > 512 || coin_count < 0 || coin_count > 128 ||
        length != (usz)(2 + coin_count)) return -1;
    for (usz coin_index = 0; coin_index < (usz)coin_count; coin_index++) {
        if (packed[2 + coin_index] < 1 || packed[2 + coin_index] > 4096) return -1;
    }

    long[513] minimum;
    minimum[0] = 0;
    for (usz current = 1; current <= (usz)amount; current++) {
        long best = 513;
        for (usz coin_index = 0; coin_index < (usz)coin_count; coin_index++) {
            usz coin = (usz)packed[2 + coin_index];
            if (coin <= current && minimum[current - coin] < 513 &&
                minimum[current - coin] + 1 < best) {
                best = minimum[current - coin] + 1;
            }
        }
        minimum[current] = best;
    }
    return minimum[(usz)amount] < 513 ? minimum[(usz)amount] : -1;
}

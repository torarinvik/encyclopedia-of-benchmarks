module maximum_ice_cream_bars;

// Buy the largest affordable prefix after sorting the prices.
fn long maximum_ice_cream_bars(long* input, usz length) @export("maximum_ice_cream_bars") {
    if (length < 1 || length > 257 || input == null) return -1;
    long coins = input[0];
    usz count = length - 1;
    if (coins < 0 || coins > 1000000) return -1;
    long[256] costs;
    for (usz index = 0; index < count; index++) {
        long cost = input[index + 1];
        if (cost < 1 || cost > 10000) return -1;
        usz position = index;
        while (position > 0 && costs[position - 1] > cost) {
            costs[position] = costs[position - 1];
            position--;
        }
        costs[position] = cost;
    }
    long bought = 0;
    for (usz index = 0; index < count; index++) {
        if (costs[index] > coins) break;
        coins -= costs[index];
        bought++;
    }
    return bought;
}

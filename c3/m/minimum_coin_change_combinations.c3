module minimum_coin_change_combinations;

const usz MAX_INPUT_LENGTH = 34;
const long INVALID_RESULT = -1;

fn long minimum_coin_change_combinations(long* values, usz length) @export("minimum_coin_change_combinations") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;

    long target = values[0];
    long count_value = values[1];
    if (target < -64 || target > 64 || count_value < 0 || count_value > 32) return INVALID_RESULT;
    usz count = (usz)count_value;
    if (length != count + 2) return INVALID_RESULT;

    long previous = 0;
    for (usz index = 0; index < count; index++) {
        long coin = values[index + 2];
        if (coin < 1 || coin > 64 || coin <= previous) return INVALID_RESULT;
        previous = coin;
    }

    if (target < 0) return 0;
    long[65] ways = {0};
    ways[0] = 1;
    for (usz index = 0; index < count; index++) {
        usz coin = (usz)values[index + 2];
        for (usz amount = coin; amount <= (usz)target; amount++) {
            ways[amount] += ways[amount - coin];
        }
    }
    return ways[(usz)target];
}

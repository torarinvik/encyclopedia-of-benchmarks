module roulette_wheel_selection;

const usz MAX_INPUT_VALUES = 131;
const long MAX_VALIDATORS = 128L;
const long MAX_STAKE = 1000000L;
const long MAX_TOTAL_STAKE = 128000000L;

fn long roulette_wheel_selection(long* input, usz length) @export("roulette_wheel_selection") {
    if (input == null || length < 3 || length > MAX_INPUT_VALUES) return -1L;

    long count_value = input[0];
    if (count_value < 1L || count_value > MAX_VALIDATORS) return -1L;
    usz count = (usz)count_value;
    if (length != count + 2) return -1L;

    long total = 0L;
    for (usz index = 0; index < count; index++) {
        long stake = input[1 + index];
        if (stake < 1L || stake > MAX_STAKE) return -1L;
        if (total > MAX_TOTAL_STAKE - stake) return -1L;
        total += stake;
    }

    long ticket = input[1 + count];
    if (ticket < 0L || ticket >= total) return -1L;

    long cumulative = 0L;
    for (usz index = 0; index < count; index++) {
        cumulative += input[1 + index];
        if (ticket < cumulative) return (long)index + 1L;
    }
    return -1L;
}

module linear_search_thread;

const long MAX_COUNT = 64;
const usz MAX_INPUT_LENGTH = MAX_COUNT + 5;

long linear_search_thread(long* input, usz length) @export("linear_search_thread") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long count_arg = input[0], left = input[1], right = input[2], target = input[3];
    if (count_arg < 1 || count_arg > MAX_COUNT || length != (usz)count_arg + 4) return -1;
    if (left < 0 || left > right || right > count_arg || target < -2147483648L || target > 2147483647L)
        return -1;
    usz count = (usz)count_arg;
    for (usz i = 0; i < count; i++)
        if (input[4 + i] < -2147483648L || input[4 + i] > 2147483647L) return -1;
    for (usz i = (usz)left; i < (usz)right; i++)
        if (input[4 + i] == target) return 1;
    return 0;
}

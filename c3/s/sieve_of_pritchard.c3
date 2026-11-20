module sieve_of_pritchard;

const long MAX_LIMIT = 1024;
const long LINK_COUNT = 1026;

fn long sieve_of_pritchard(long* input, usz length) @export("sieve_of_pritchard") {
    if (input == null || length < 1 || length > 2) return -1;
    if (length != 1 || input[0] < 2 || input[0] > MAX_LIMIT) return -1;

    long limit = input[0];
    long sentinel = limit + 1;
    int[LINK_COUNT] next_node = zeroed;
    int[LINK_COUNT] previous = zeroed;
    next_node[1] = (int)sentinel;
    next_node[(usz)sentinel] = (int)sentinel;
    previous[(usz)sentinel] = 1;
    long wheel_length = 2;
    long prime = 3;
    long prime_count = 1;

    while (prime * prime <= limit) {
        if (wheel_length < limit) {
            long product = prime * wheel_length;
            long target = product < limit ? product : limit;
            long wheel_value = 1;
            long candidate = wheel_length + 1;
            while (candidate <= target) {
                int tail = previous[(usz)sentinel];
                next_node[(usz)tail] = (int)candidate;
                previous[(usz)candidate] = tail;
                next_node[(usz)candidate] = (int)sentinel;
                previous[(usz)sentinel] = (int)candidate;
                wheel_value = next_node[(usz)wheel_value];
                candidate = wheel_length + wheel_value;
            }
            wheel_length = target;
        }
        long wheel_value = prime;
        while (prime * wheel_value <= wheel_length)
            wheel_value = next_node[(usz)wheel_value];
        while (wheel_value > 1) {
            wheel_value = previous[(usz)wheel_value];
            long removed = prime * wheel_value;
            int left = previous[(usz)removed];
            int right = next_node[(usz)removed];
            next_node[(usz)left] = right;
            previous[(usz)right] = left;
        }
        prime_count++;
        prime = next_node[1];
    }

    if (wheel_length < limit) {
        long wheel_value = 1;
        long candidate = wheel_length + 1;
        while (candidate <= limit) {
            int tail = previous[(usz)sentinel];
            next_node[(usz)tail] = (int)candidate;
            previous[(usz)candidate] = tail;
            next_node[(usz)candidate] = (int)sentinel;
            previous[(usz)sentinel] = (int)candidate;
            wheel_value = next_node[(usz)wheel_value];
            candidate = wheel_length + wheel_value;
        }
        wheel_length = limit;
    }

    long remaining = 0;
    long value = next_node[1];
    while (value != sentinel) {
        remaining++;
        value = next_node[(usz)value];
    }
    return prime_count + remaining;
}

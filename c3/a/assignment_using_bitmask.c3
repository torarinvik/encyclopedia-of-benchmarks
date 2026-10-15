module assignment_using_bitmask;

// Count task assignments with one distinct eligible task per person.
fn long assignment_using_bitmask(long* input, usz length) @export("assignment_using_bitmask") {
    if (input == null || length < 2) return -1;
    long people = input[0];
    long tasks = input[1];
    if (people < 0 || people > 10 || tasks < 0 || tasks > 10 || length != (usz)(2 + people)) return -1;
    ulong valid_tasks = (ulong)1 << (usz)tasks;
    for (usz person = 0; person < (usz)people; person++) {
        if (input[2 + person] < 0 || (ulong)input[2 + person] >= valid_tasks) return -1;
    }

    usz states = (usz)1 << (usz)people;
    long[4096] ways;
    long[4096] next;
    for (usz mask = 0; mask < 4096; mask++) {
        ways[mask] = 0;
        next[mask] = 0;
    }
    ways[0] = 1;
    for (long task = 0; task < tasks; task++) {
        for (usz mask = 0; mask < states; mask++) next[mask] = 0;
        for (usz mask = 0; mask < states; mask++) {
            long count = ways[mask];
            if (count == 0) continue;
            next[mask] += count;
            for (usz person = 0; person < (usz)people; person++) {
                usz bit = (usz)1 << person;
                if ((mask & bit) == 0 && (input[2 + person] & ((long)1 << (usz)task)) != 0) {
                    next[mask | bit] += count;
                }
            }
        }
        for (usz mask = 0; mask < states; mask++) ways[mask] = next[mask];
    }
    return ways[states - 1];
}

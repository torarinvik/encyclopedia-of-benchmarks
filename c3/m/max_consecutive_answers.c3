module max_consecutive_answers;

const usz MAX_BITS = 1024;

fn usz longest_for_target(long* input, usz count, usz allowed, long target) {
    usz left = 0;
    usz opposite = 0;
    usz best = 0;
    for (usz right = 0; right < count; right++) {
        if (input[right + 1] != target) opposite++;
        while (opposite > allowed) {
            if (input[left + 1] != target) opposite--;
            left++;
        }
        usz window = right - left + 1;
        if (window > best) best = window;
    }
    return best;
}

fn long max_consecutive_answers(long* input, usz length) @export("max_consecutive_answers") {
    if (input == null || length == 0 || length > MAX_BITS + 1) return -1;
    usz count = length - 1;
    if (input[0] < 0 || input[0] > (long)count) return -1;
    for (usz i = 0; i < count; i++) {
        if (input[i + 1] != 0 && input[i + 1] != 1) return -1;
    }
    usz allowed = (usz)input[0];
    usz true_target = longest_for_target(input, count, allowed, 1);
    usz false_target = longest_for_target(input, count, allowed, 0);
    return (long)(true_target > false_target ? true_target : false_target);
}

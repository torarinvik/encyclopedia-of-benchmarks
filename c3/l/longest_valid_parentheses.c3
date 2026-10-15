module longest_valid_parentheses;

const MAX_LENGTH = 4096;

// Memoized endpoint recurrence, evaluated bottom-up from right to left.
fn long longest_valid_parentheses(long* input, usz length) @export("longest_valid_parentheses") {
    if (length > MAX_LENGTH || (length != 0 && input == null)) { return -1; }
    usz[MAX_LENGTH] end_exclusive;
    for (usz index = 0; index < length; index++) {
        if (input[index] != 40 && input[index] != 41) { return -1; }
        end_exclusive[index] = 0;
    }

    usz best = 0;
    for (usz remaining = length; remaining > 0; remaining--) {
        usz index = remaining - 1;
        if (input[index] == 40) {
            if (index + 1 < length && input[index + 1] == 41) {
                end_exclusive[index] = index + 2;
                if (index + 2 < length && end_exclusive[index + 2] > end_exclusive[index]) {
                    end_exclusive[index] = end_exclusive[index + 2];
                }
            } else if (index + 1 < length) {
                usz nested_end = end_exclusive[index + 1];
                if (nested_end > 0 && nested_end < length && input[nested_end] == 41) {
                    end_exclusive[index] = nested_end + 1;
                    if (nested_end + 1 < length && end_exclusive[nested_end + 1] > end_exclusive[index]) {
                        end_exclusive[index] = end_exclusive[nested_end + 1];
                    }
                }
            }
        }
        if (end_exclusive[index] > index && end_exclusive[index] - index > best) {
            best = end_exclusive[index] - index;
        }
    }
    return (long)best;
}

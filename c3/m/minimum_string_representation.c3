module minimum_string_representation;

// Least cyclic rotation by two-candidate elimination.
fn long minimum_string_representation(long* values, usz length) @export("minimum_string_representation") {
    if (length > 4096) return -1;
    if (length == 0) return 0;
    if (values == null) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }

    usz left = 0, right = 1, matched = 0;
    while (left < length && right < length && matched < length) {
        long a = values[(left + matched) % length];
        long b = values[(right + matched) % length];
        if (a == b) {
            matched += 1;
            continue;
        }
        if (a > b) {
            left += matched + 1;
            if (left == right) left += 1;
        } else {
            right += matched + 1;
            if (left == right) right += 1;
        }
        matched = 0;
    }
    return (long)(left < right ? left : right);
}

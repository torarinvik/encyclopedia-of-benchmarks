module number_of_ways_select_buildings;

const MAX_LENGTH = 4096;

fn long count_for_target(long* values, usz length, long target) {
    long first_count = 0;
    long middle_count = 0;
    long ways = 0;
    for (usz index = 0; index < length; index++) {
        if (values[index] == target) {
            ways += middle_count;
            first_count++;
        } else {
            middle_count += first_count;
        }
    }
    return ways;
}

// Count alternating 0-1-0 and 1-0-1 subsequences with two linear scans.
fn long number_of_ways_to_select_buildings(long* values, usz length) @export("number_of_ways_to_select_buildings") {
    if (length == 0) { return 0; }
    if (values == null || length > MAX_LENGTH) { return -1; }
    for (usz index = 0; index < length; index++) {
        if (values[index] != 48 && values[index] != 49) { return -1; }
    }
    return count_for_target(values, length, 48) + count_for_target(values, length, 49);
}

/// Count alternating 0-1-0 and 1-0-1 subsequences with two linear scans.
const MAX_LENGTH: usize = 4096;

fn count_for_target(values: [*]const i64, length: usize, target: i64) i64 {
    var first_count: i64 = 0;
    var middle_count: i64 = 0;
    var ways: i64 = 0;
    for (0..length) |index| {
        if (values[index] == target) {
            ways += middle_count;
            first_count += 1;
        } else {
            middle_count += first_count;
        }
    }
    return ways;
}

export fn number_of_ways_to_select_buildings(values: [*c]const i64, length: usize) i64 {
    if (length == 0) return 0;
    if (values == null or length > MAX_LENGTH) return -1;
    for (0..length) |index| {
        if (values[index] != 48 and values[index] != 49) return -1;
    }
    return count_for_target(values, length, 48) + count_for_target(values, length, 49);
}

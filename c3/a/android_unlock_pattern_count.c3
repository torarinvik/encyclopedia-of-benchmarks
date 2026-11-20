module android_unlock_pattern_count;

fn int middle_point(int first, int second) {
    if (first == second) return -1;
    int first_x = first % 3;
    int first_y = first / 3;
    int second_x = second % 3;
    int second_y = second / 3;
    int delta_x = second_x - first_x;
    int delta_y = second_y - first_y;
    if (delta_x % 2 != 0 || delta_y % 2 != 0) return -1;
    int middle = ((first_y + second_y) / 2) * 3 + (first_x + second_x) / 2;
    if (middle == first || middle == second) return -1;
    return middle;
}

fn long count_from(int last, long visited, int used, int target) {
    if (used == target) return 1;
    long count = 0;
    for (int next = 0; next < 9; next++) {
        long bit = 1 << next;
        if ((visited & bit) == 0) {
            int middle = middle_point(last, next);
            if (middle < 0 || (visited & (1 << middle)) != 0)
                count += count_from(next, visited | bit, used + 1, target);
        }
    }
    return count;
}

fn long android_unlock_pattern_count(long* input, usz length) @export("android_unlock_pattern_count") {
    if (input == null || length != 1) return -1;
    long target = input[0];
    if (target < 4 || target > 9) return -1;
    long count = 0;
    for (int start = 0; start < 9; start++)
        count += count_from(start, 1 << start, 1, (int)target);
    return count;
}

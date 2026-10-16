module reversort_cost;

fn long reversort_cost(long* values, usz length) @export("reversort_cost") {
    if (length > 256) return -1;
    long[256] working;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -2147483648 || values[index] > 2147483647) return -1;
        working[index] = values[index];
    }
    long cost = 0;
    for (usz index = 0; index + 1 < length; index++) {
        usz minimum = index;
        for (usz probe = index + 1; probe < length; probe++) {
            if (working[probe] < working[minimum]) minimum = probe;
        }
        usz left = index;
        usz right = minimum;
        while (left < right) {
            long temporary = working[left];
            working[left] = working[right];
            working[right] = temporary;
            left++;
            right--;
        }
        cost += (long)(minimum - index + 1);
    }
    return cost;
}

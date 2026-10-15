module max_bags_full_capacity;

const MAX_INPUT_LENGTH = 16384;
const MAX_BAGS = 8191;

fn void sift_down(long* values, usz root, usz end)
{
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) child++;
        if (values[root] >= values[child]) break;
        long temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

fn long maximum_bags_with_full_capacity(long* input, usz length) @export("maximum_bags_with_full_capacity")
{
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long remaining = input[0];
    if (remaining < 0 || remaining > 1000000000) return -1;
    if (input[1] < 0 || input[1] > MAX_BAGS) return -1;
    usz count = (usz)input[1];
    if (length != 2 + 2 * count) return -1;
    long[MAX_BAGS] deficits;
    for (usz index = 0; index < count; index++) {
        long capacity = input[2 + index];
        long rocks = input[2 + count + index];
        if (capacity < 1 || capacity > 100000 || rocks < 0 || rocks > capacity) return -1;
        deficits[index] = capacity - rocks;
    }
    for (usz start = count / 2; start > 0;) {
        start--;
        sift_down(&deficits[0], start, count);
    }
    for (usz end = count; end > 1;) {
        end--;
        long temporary = deficits[0];
        deficits[0] = deficits[end];
        deficits[end] = temporary;
        sift_down(&deficits[0], 0, end);
    }
    long full_bags = 0;
    for (usz index = 0; index < count; index++) {
        if (deficits[index] > remaining) break;
        remaining -= deficits[index];
        full_bags++;
    }
    return full_bags;
}

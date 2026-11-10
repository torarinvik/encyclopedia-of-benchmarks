module three_sum_closest;

const usz MAX_ITEMS = 512;
const usz SHORT_ITEMS = 16;
const long INVALID_RESULT = -9000000000000000000;

fn bool fits_i32(long value)
{
    return value >= -2147483648 && value <= 2147483647;
}

fn void sift_down(int* values, usz root, usz count)
{
    int value = values[root];
    while (root < count / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < count && values[child] < values[child + 1]) ++child;
        if (value >= values[child]) break;
        values[root] = values[child];
        root = child;
    }
    values[root] = value;
}

fn long sum_rank(long sum, long target)
{
    long delta = sum - target;
    return delta < 0 ? -2 * delta : 2 * delta + 1;
}

fn long ranked_sum(long rank, long target)
{
    return (rank & 1) != 0 ? target + rank / 2 : target - rank / 2;
}

fn long closest_sorted(int* values, usz count, long target)
{
    long smallest = (long)values[0] + values[1] + values[2];
    if (target <= smallest) return smallest;
    long last_pair = (long)values[count - 1] + values[count - 2];
    long largest = last_pair + values[count - 3];
    if (target >= largest) return largest;

    long best_rank = sum_rank(smallest, target);
    for (usz first = 0; first + 2 < count; ++first) {
        long fixed = values[first];
        if (first > 0 && fixed == values[first - 1]) continue;
        long minimum = fixed + values[first + 1] + values[first + 2];
        if (minimum >= target) {
            return sum_rank(minimum, target) < best_rank ? minimum : ranked_sum(best_rank, target);
        }
        long maximum = fixed + last_pair;
        if (maximum <= target) {
            long rank = sum_rank(maximum, target);
            if (rank < best_rank) best_rank = rank;
            continue;
        }
        usz left = first + 1;
        usz right = count - 1;
        while (left < right) {
            long sum = fixed + values[left] + values[right];
            long rank = sum_rank(sum, target);
            if (rank < best_rank) best_rank = rank;
            if (sum < target) { ++left; }
            else if (sum > target) { --right; }
            else { return sum; }
        }
    }
    return ranked_sum(best_rank, target);
}

fn long sort_and_find(long* input, usz count, long target, int* values)
{
    for (usz i = 0; i < count; ++i) {
        long value = input[i + 2];
        if (!fits_i32(value)) return INVALID_RESULT;
        values[i] = (int)value;
    }
    for (usz start = count / 2; start > 0; --start) sift_down(values, start - 1, count);
    for (usz end = count; end > 1;) {
        --end;
        int value = values[0];
        values[0] = values[end];
        values[end] = value;
        sift_down(values, 0, end);
    }
    return closest_sorted(values, count, target);
}

fn long three_sum_closest(long* input, usz length) @export("three_sum_closest")
{
    if (input == null || length < 5 || length > MAX_ITEMS + 2) return INVALID_RESULT;
    long target = input[0];
    long count_value = input[1];
    if (!fits_i32(target) || count_value < 3 || count_value > (long)MAX_ITEMS) return INVALID_RESULT;
    usz count = (usz)count_value;
    if (length != count + 2) return INVALID_RESULT;
    if (count == 3) {
        long first = input[2];
        long second = input[3];
        long third = input[4];
        return fits_i32(first) && fits_i32(second) && fits_i32(third)
            ? first + second + third : INVALID_RESULT;
    }
    if (count <= SHORT_ITEMS) {
        int[SHORT_ITEMS] values;
        return sort_and_find(input, count, target, &values[0]);
    }
    int[MAX_ITEMS] values;
    return sort_and_find(input, count, target, &values[0]);
}

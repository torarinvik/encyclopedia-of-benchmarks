module bfprt;

const int MAX_SIZE = 1024;
const long INVALID = -2147483649L;

fn void bfprt_swap(int* values, int left, int right) {
    int temporary = values[left];
    values[left] = values[right];
    values[right] = temporary;
}

fn void bfprt_insertion_sort(int* values, int left, int right) {
    for (int index = left + 1; index <= right; index++) {
        int cursor = index;
        while (cursor > left && values[cursor - 1] > values[cursor]) {
            bfprt_swap(values, cursor - 1, cursor);
            cursor--;
        }
    }
}

fn int bfprt_select(int* values, int left, int right, int rank);

fn int bfprt_median_of_medians(int* values, int left, int right) {
    int count = right - left + 1;
    int groups = (count + 4) / 5;
    for (int group = 0; group < groups; group++) {
        int group_left = left + group * 5;
        int group_right = group_left + 4;
        if (group_right > right) group_right = right;
        bfprt_insertion_sort(values, group_left, group_right);
        int median = group_left + (group_right - group_left + 1) / 2;
        bfprt_swap(values, left + group, median);
    }
    if (groups == 1) return values[left];
    return bfprt_select(values, left, left + groups - 1, left + groups / 2);
}

fn int bfprt_select(int* values, int left, int right, int rank) {
    while (left < right) {
        int pivot = bfprt_median_of_medians(values, left, right);
        int less = left, current = left, greater = right + 1;
        while (current < greater) {
            if (values[current] < pivot) {
                bfprt_swap(values, less, current);
                less++;
                current++;
            } else if (values[current] > pivot) {
                greater--;
                bfprt_swap(values, current, greater);
            } else {
                current++;
            }
        }
        if (rank < less) right = less - 1;
        else if (rank >= greater) left = greater;
        else return values[rank];
    }
    return values[left];
}

fn long bfprt(long* input, usz length) @export("bfprt") {
    if (input == null || length < 2) return INVALID;
    long count_value = input[0], rank_value = input[1];
    if (count_value < 1 || count_value > MAX_SIZE) return INVALID;
    int count = (int)count_value;
    if (length != (usz)(count + 2) || rank_value < 1 || rank_value > count_value) return INVALID;

    int[MAX_SIZE] values;
    for (int index = 0; index < count; index++) {
        long value = input[index + 2];
        if (value < -2147483648L || value > 2147483647L) return INVALID;
        values[index] = (int)value;
    }
    return bfprt_select(&values[0], 0, count - 1, (int)(rank_value - 1));
}

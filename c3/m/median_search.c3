module median_search;

const usz MAX_VALUES = 25;
const usz MAX_INPUT_LENGTH = 28;

fn void insertion_sort(long* values, usz start, usz end) {
    for (usz index = start + 1; index < end; index += 1) {
        long value = values[index];
        usz position = index;
        while (position > start && values[position - 1] > value) {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = value;
    }
}

fn long select_kth(long* values, usz length, usz rank) {
    long[5] medians;
    usz median_count = 0;
    for (usz start = 0; start < length; start += 5) {
        usz end = start + 5;
        if (end > length) end = length;
        insertion_sort(values, start, end);
        medians[median_count] = values[(start + end) / 2];
        median_count += 1;
    }
    insertion_sort(&medians[0], 0, median_count);
    long pivot = medians[(median_count - 1) / 2];

    long[MAX_VALUES] lower, higher;
    usz lower_count = 0, higher_count = 0;
    for (usz index = 0; index < length; index += 1) {
        if (values[index] < pivot) {
            lower[lower_count] = values[index];
            lower_count += 1;
        } else if (values[index] > pivot) {
            higher[higher_count] = values[index];
            higher_count += 1;
        }
    }
    if (rank < lower_count) return select_kth(&lower[0], lower_count, rank);
    if (rank > lower_count) return select_kth(&higher[0], higher_count, rank - lower_count - 1);
    return pivot;
}

fn long median_search(long* input, usz length) @export("median_search") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0], rank_value = input[1];
    if (count_value < 1 || count_value > (long)MAX_VALUES || rank_value < 0 ||
        rank_value >= count_value || length != (usz)count_value + 2) return -1;

    usz count = (usz)count_value;
    long[MAX_VALUES] values;
    for (usz index = 0; index < count; index += 1) {
        long value = input[index + 2];
        if (value < 0 || value > 2147483647) return -1;
        for (usz previous = 0; previous < index; previous += 1) {
            if (values[previous] == value) return -1;
        }
        values[index] = value;
    }
    return select_kth(&values[0], count, (usz)rank_value);
}

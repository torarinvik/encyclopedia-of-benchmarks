module merge_sorter;

const MAX_VALUES = 1024;

fn void merge_sorter_range(long* values, long* scratch, usz low, usz high) {
    if (high - low <= 1) return;
    usz middle = low + (high - low) / 2;
    merge_sorter_range(values, scratch, low, middle);
    merge_sorter_range(values, scratch, middle, high);
    usz left = low;
    usz right = middle;
    usz output = low;
    while (left < middle && right < high) {
        if (values[left] <= values[right]) {
            scratch[output++] = values[left++];
        } else {
            scratch[output++] = values[right++];
        }
    }
    while (left < middle) scratch[output++] = values[left++];
    while (right < high) scratch[output++] = values[right++];
    for (usz index = low; index < high; index++) values[index] = scratch[index];
}

fn void merge_sorter(long* values, usz length) @export("merge_sorter") {
    if (length > MAX_VALUES) return;
    long[MAX_VALUES] scratch;
    merge_sorter_range(values, &scratch[0], 0, length);
}

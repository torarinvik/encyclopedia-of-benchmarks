module adaptive_merge_sort;

const MAX_VALUES = 1024;

fn void adaptive_merge_sort_range(long* values, long* scratch, usz low, usz high) {
    if (high - low <= 1) return;
    usz middle = low + (high - low) / 2;
    adaptive_merge_sort_range(values, scratch, low, middle);
    adaptive_merge_sort_range(values, scratch, middle, high);
    if values[middle - 1] <= values[middle] { return; }
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

fn void adaptive_merge_sort(long* values, usz length) @export("adaptive_merge_sort") {
    if (length > MAX_VALUES) return;
    long[MAX_VALUES] scratch;
    adaptive_merge_sort_range(values, &scratch[0], 0, length);
}

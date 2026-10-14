module merge_sort_nr;

const MAX_VALUES = 1024;

fn void merge_sort_nr(long* values, usz length) @export("merge_sort_nr") {
    if (length > MAX_VALUES) return;
    long[MAX_VALUES] scratch;
    for (usz width = 1; width < length; width *= 2) {
        for (usz start = 0; start < length; start += width * 2) {
            usz middle = start + width;
            if (middle > length) middle = length;
            usz end = middle + width;
            if (end > length) end = length;
            usz left = start;
            usz right = middle;
            usz output = start;
            while (left < middle && right < end) {
                if (values[left] <= values[right]) {
                    scratch[output++] = values[left++];
                } else {
                    scratch[output++] = values[right++];
                }
            }
            while (left < middle) scratch[output++] = values[left++];
            while (right < end) scratch[output++] = values[right++];
        }
        for (usz index = 0; index < length; index++) values[index] = scratch[index];
    }
}

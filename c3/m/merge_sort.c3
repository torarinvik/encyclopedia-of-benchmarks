module merge_sort;

fn void merge_sort(long* values, long* scratch, usz length) @export("merge_sort")
{
    for (usz width = 1; width < length;) {
        usz low = 0;
        while (low < length) {
            usz middle = low + width;
            if (middle > length) middle = length;
            usz high = middle + width;
            if (high > length) high = length;
            usz left = low;
            usz right = middle;
            usz output = low;
            while (left < middle && right < high) {
                if (values[left] <= values[right]) scratch[output++] = values[left++];
                else scratch[output++] = values[right++];
            }
            while (left < middle) scratch[output++] = values[left++];
            while (right < high) scratch[output++] = values[right++];
            for (usz index = low; index < high; index++) values[index] = scratch[index];
            low = high;
        }
        if (width > length / 2) break;
        width *= 2;
    }
}

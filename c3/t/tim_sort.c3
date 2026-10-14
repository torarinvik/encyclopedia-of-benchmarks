module tim_sort;

const usz TIM_SORT_RUN = 32;

fn void insertion_sort_run(long* values, usz low, usz high)
{
    for (usz index = low + 1; index < high; index++) {
        long key = values[index];
        usz cursor = index;
        while (cursor > low && values[cursor - 1] > key) {
            values[cursor] = values[cursor - 1];
            cursor--;
        }
        values[cursor] = key;
    }
}

fn void merge_runs(long* values, long* scratch, usz left, usz middle, usz right)
{
    for (usz index = left; index < right; index++) scratch[index] = values[index];
    usz first = left;
    usz second = middle;
    for (usz output = left; output < right; output++) {
        if (first == middle) {
            values[output] = scratch[second];
            second++;
        } else if (second == right || scratch[first] <= scratch[second]) {
            values[output] = scratch[first];
            first++;
        } else {
            values[output] = scratch[second];
            second++;
        }
    }
}

fn void tim_sort(long* values, long* scratch, usz length) @export("tim_sort")
{
    if (length < 2) return;
    usz start = 0;
    while (start < length) {
        usz remaining = length - start;
        usz end = remaining < TIM_SORT_RUN ? length : start + TIM_SORT_RUN;
        insertion_sort_run(values, start, end);
        start = end;
    }

    usz width = TIM_SORT_RUN;
    while (width < length) {
        usz left = 0;
        while (left < length) {
            usz left_remaining = length - left;
            usz middle = left + (width < left_remaining ? width : left_remaining);
            usz right_remaining = length - middle;
            usz right = middle + (width < right_remaining ? width : right_remaining);
            if (middle < right) merge_runs(values, scratch, left, middle, right);
            left = right;
        }
        if (width >= length - width) break;
        width *= 2;
    }
}

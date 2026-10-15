const MAX_VALUES: usize = 1024;

fn medianOfThree(first: i64, middle: i64, last: i64) i64 {
    if (first < middle) {
        if (middle < last) return middle;
        if (first < last) return last;
        return first;
    }
    if (first < last) return first;
    if (middle < last) return last;
    return middle;
}

export fn quick_select(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_VALUES) return -1;
    var scratch: [MAX_VALUES]i64 = undefined;
    for (0..length) |index| scratch[index] = values[index];

    const target = length / 2;
    var low: usize = 0;
    var high = length;
    while (high - low > 1) {
        const middle = low + (high - low) / 2;
        const pivot = medianOfThree(scratch[low], scratch[middle], scratch[high - 1]);
        var less = low;
        var scan = low;
        var greater = high;
        while (scan < greater) {
            if (scratch[scan] < pivot) {
                const temporary = scratch[less];
                scratch[less] = scratch[scan];
                scratch[scan] = temporary;
                less += 1;
                scan += 1;
            } else if (scratch[scan] > pivot) {
                greater -= 1;
                const temporary = scratch[greater];
                scratch[greater] = scratch[scan];
                scratch[scan] = temporary;
            } else {
                scan += 1;
            }
        }
        if (target < less) high = less
        else if (target >= greater) low = greater
        else return pivot;
    }
    return scratch[target];
}

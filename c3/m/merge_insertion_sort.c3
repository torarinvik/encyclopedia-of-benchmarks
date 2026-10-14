module merge_insertion_sort;

const MAX_VALUES = 256;
const MAX_PAIRS = 128;

fn void sort_pairs(long* low, long* high, long* scratch_low, long* scratch_high, usz count) {
    for (usz width = 1; width < count; width *= 2) {
        for (usz start = 0; start < count; start += width * 2) {
            usz middle = start + width;
            if (middle > count) middle = count;
            usz end = middle + width;
            if (end > count) end = count;
            usz left = start;
            usz right = middle;
            usz output = start;
            while (left < middle && right < end) {
                if (low[left] <= low[right]) {
                    scratch_low[output] = low[left]; scratch_high[output++] = high[left++];
                } else {
                    scratch_low[output] = low[right]; scratch_high[output++] = high[right++];
                }
            }
            while (left < middle) { scratch_low[output] = low[left]; scratch_high[output++] = high[left++]; }
            while (right < end) { scratch_low[output] = low[right]; scratch_high[output++] = high[right++]; }
            for (usz index = start; index < end; index++) { low[index] = scratch_low[index]; high[index] = scratch_high[index]; }
        }
        if (width > count / 2) break;
    }
}

fn void binary_insert(long* values, usz* length, long item) {
    usz low = 0;
    usz high = *length;
    while (low < high) {
        usz middle = low + (high - low) / 2;
        if (values[middle] < item) {
            low = middle + 1;
        } else {
            high = middle;
        }
    }
    for (usz index = *length; index > low; index--) values[index] = values[index - 1];
    values[low] = item;
    *length = *length + 1;
}

fn void merge_insertion_sort(long* values, usz length) @export("merge_insertion_sort") {
    if (length > MAX_VALUES) return;
    long[MAX_PAIRS] pair_low, pair_high, scratch_low, scratch_high;
    long[MAX_VALUES] chain;
    usz pair_count = length / 2;
    for (usz pair = 0; pair < pair_count; pair++) {
        long first = values[pair * 2];
        long second = values[pair * 2 + 1];
        if (first <= second) { pair_low[pair] = first; pair_high[pair] = second; }
        else { pair_low[pair] = second; pair_high[pair] = first; }
    }
    sort_pairs(&pair_low[0], &pair_high[0], &scratch_low[0], &scratch_high[0], pair_count);
    usz chain_length = 0;
    for (usz pair = 0; pair < pair_count; pair++) chain[chain_length++] = pair_low[pair];
    if (pair_count > 0) chain[chain_length++] = pair_high[pair_count - 1];
    if (length % 2 != 0) binary_insert(&chain[0], &chain_length, values[length - 1]);
    for (usz pair = 0; pair + 1 < pair_count; pair++) binary_insert(&chain[0], &chain_length, pair_high[pair]);
    for (usz index = 0; index < length; index++) values[index] = chain[index];
}

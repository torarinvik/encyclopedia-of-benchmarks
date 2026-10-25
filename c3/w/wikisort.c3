module wikisort;

const WIKISORT_CACHE_SIZE: usz = 512;
const WIKISORT_RUN_SIZE: usz = 16;
const WIKISORT_MAX_LENGTH: usz = 2048;

fn void reverse_range(long* values, usz first, usz last) {
    while (first < last) {
        last -= 1;
        if (first >= last) break;
        long item = values[first];
        values[first] = values[last];
        values[last] = item;
        first += 1;
    }
}

fn void insertion_sort(long* values, usz first, usz last) {
    for (usz index = first + 1; index < last; index += 1) {
        long item = values[index];
        usz position = index;
        while (position > first && item < values[position - 1]) {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = item;
    }
}

fn void rotate_adjacent(long* values, long* scratch, usz first, usz middle, usz last, usz cache_size) {
    usz left_length = middle - first;
    usz right_length = last - middle;
    if (left_length == 0 || right_length == 0) return;
    if (left_length <= right_length && left_length <= cache_size) {
        for (usz index = 0; index < left_length; index += 1) scratch[index] = values[first + index];
        for (usz index = 0; index < right_length; index += 1) values[first + index] = values[middle + index];
        for (usz index = 0; index < left_length; index += 1) values[first + right_length + index] = scratch[index];
        return;
    }
    if (right_length < left_length && right_length <= cache_size) {
        for (usz index = 0; index < right_length; index += 1) scratch[index] = values[middle + index];
        for (usz index = left_length; index > 0; index -= 1) values[first + right_length + index - 1] = values[first + index - 1];
        for (usz index = 0; index < right_length; index += 1) values[first + index] = scratch[index];
        return;
    }
    reverse_range(values, first, middle);
    reverse_range(values, middle, last);
    reverse_range(values, first, last);
}

fn void merge_from_cache(long* values, long* scratch, usz first, usz middle, usz last) {
    usz left_length = middle - first;
    for (usz index = 0; index < left_length; index += 1) scratch[index] = values[first + index];
    usz left = 0;
    usz right = middle;
    usz output = first;
    while (left < left_length && right < last) {
        if (scratch[left] <= values[right]) {
            values[output] = scratch[left];
            left += 1;
        } else {
            values[output] = values[right];
            right += 1;
        }
        output += 1;
    }
    while (left < left_length) {
        values[output] = scratch[left];
        left += 1;
        output += 1;
    }
}

fn void block_rotation_merge(long* values, long* scratch, usz first, usz middle, usz last, usz cache_size) {
    usz total = last - first;
    usz block_size = 1;
    while (block_size + 1 <= total / (block_size + 1)) block_size += 1;
    usz left = first;
    while (left < middle && middle < last) {
        if (values[left] <= values[middle]) {
            long boundary_value = values[middle];
            usz low = left;
            usz high = middle;
            while (low < high) {
                usz probe = low + (high - low) / 2;
                if (values[probe] <= boundary_value) low = probe + 1;
                else high = probe;
            }
            left = low;
        } else {
            long key = values[left];
            usz low = middle;
            usz high = last;
            while (low < high) {
                usz probe = low + (high - low) / 2;
                if (values[probe] < key) low = probe + 1;
                else high = probe;
            }
            usz block_end = low;
            if (block_end - middle > block_size) block_end = middle + block_size;
            usz moved = block_end - middle;
            if (moved == 0) left += 1;
            else {
                rotate_adjacent(values, scratch, left, middle, block_end, cache_size);
                left += moved;
                middle += moved;
            }
        }
    }
}

fn void wikisort(long* values, long* scratch, usz length) @export("wikisort") {
    if (length < 2 || length > WIKISORT_MAX_LENGTH) return;
    usz cache_size = length < WIKISORT_CACHE_SIZE ? length : WIKISORT_CACHE_SIZE;
    if (length <= 32) {
        insertion_sort(values, 0, length);
        return;
    }
    for (usz start = 0; start < length; start += WIKISORT_RUN_SIZE) {
        usz end = start + WIKISORT_RUN_SIZE;
        if (end > length) end = length;
        insertion_sort(values, start, end);
    }
    for (usz width = WIKISORT_RUN_SIZE; width < length;) {
        usz first = 0;
        while (first < length) {
            usz middle = first + width;
            if (middle > length) middle = length;
            usz last = middle + width;
            if (last > length) last = length;
            if (middle < last && values[middle] < values[middle - 1]) {
                if (values[last - 1] < values[first]) rotate_adjacent(values, scratch, first, middle, last, cache_size);
                else if (middle - first <= cache_size) merge_from_cache(values, scratch, first, middle, last);
                else block_rotation_merge(values, scratch, first, middle, last, cache_size);
            }
            first = last;
        }
        if (width > length / 2) break;
        width *= 2;
    }
}

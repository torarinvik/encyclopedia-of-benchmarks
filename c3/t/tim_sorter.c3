module tim_sorter;

const usz MAX_ITEMS = 512;
const usz MAX_PARSEABLE_INPUT_LENGTH = 1026;
const usz MIN_MERGE = 32;
const long HASH_MULTIPLIER = 1000003;
const long HASH_MODULUS = 1000000007;

struct Item { long key; long item_id; }

fn void reverse_range(Item* items, usz start_arg, usz end_arg) {
    usz start = start_arg;
    usz end = end_arg;
    while (start < end) {
        end--;
        if (start >= end) break;
        Item temporary = items[start];
        items[start] = items[end];
        start++;
        items[end] = temporary;
    }
}

fn usz count_run_and_make_ascending(Item* items, usz start, usz count) {
    usz run_hi = start + 1;
    if (run_hi == count) return 1;
    if (items[run_hi].key < items[start].key) {
        run_hi++;
        while (run_hi < count && items[run_hi].key < items[run_hi - 1].key) run_hi++;
        reverse_range(items, start, run_hi);
    } else {
        run_hi++;
        while (run_hi < count && items[run_hi].key >= items[run_hi - 1].key) run_hi++;
    }
    return run_hi - start;
}

fn void binary_sort(Item* items, usz start, usz end, usz first_arg) {
    usz first = first_arg;
    if (first >= end || first <= start) first = start + 1;
    while (first < end) {
        Item target = items[first];
        usz left = start;
        usz right = first;
        while (left < right) {
            usz middle = (left + right) / 2;
            if (target.key < items[middle].key) right = middle;
            else left = middle + 1;
        }
        for (usz index = first; index > left; index--) items[index] = items[index - 1];
        items[left] = target;
        first++;
    }
}

fn usz min_run_length(usz total_arg) {
    usz total = total_arg;
    usz remainder = 0;
    while (total >= MIN_MERGE) {
        remainder |= total & 1;
        total >>= 1;
    }
    return total + remainder;
}

fn void merge_at(Item* items, usz* run_base, usz* run_lengths, usz* stack_size,
                 usz index) {
    usz base_a = run_base[index];
    usz len_a = run_lengths[index];
    usz base_b = run_base[index + 1];
    usz len_b = run_lengths[index + 1];
    run_lengths[index] = len_a + len_b;
    if (index == *stack_size - 3) {
        run_base[index + 1] = run_base[index + 2];
        run_lengths[index + 1] = run_lengths[index + 2];
    }
    *stack_size -= 1;

    Item[MAX_ITEMS] temporary;
    for (usz offset = 0; offset < len_a; offset++) temporary[offset] = items[base_a + offset];
    usz left = 0;
    usz right = base_b;
    usz destination = base_a;
    usz right_end = base_b + len_b;
    while (left < len_a && right < right_end) {
        if (temporary[left].key <= items[right].key) {
            items[destination] = temporary[left];
            left++;
        } else {
            items[destination] = items[right];
            right++;
        }
        destination++;
    }
    while (left < len_a) {
        items[destination] = temporary[left];
        left++;
        destination++;
    }
}

fn void merge_collapse(Item* items, usz* run_base, usz* run_lengths, usz* stack_size) {
    while (*stack_size > 1) {
        usz index = *stack_size - 2;
        if (index > 0 && run_lengths[index - 1] <= run_lengths[index] + run_lengths[index + 1]) {
            if (run_lengths[index - 1] < run_lengths[index + 1]) index--;
            merge_at(items, run_base, run_lengths, stack_size, index);
        } else if (run_lengths[index] <= run_lengths[index + 1]) {
            merge_at(items, run_base, run_lengths, stack_size, index);
        } else {
            break;
        }
    }
}

fn void merge_force_collapse(Item* items, usz* run_base, usz* run_lengths, usz* stack_size) {
    while (*stack_size > 1) {
        usz index = *stack_size - 2;
        if (index > 0 && run_lengths[index - 1] < run_lengths[index + 1]) index--;
        merge_at(items, run_base, run_lengths, stack_size, index);
    }
}

fn void tim_sort(Item* items, usz count) {
    if (count < MIN_MERGE) {
        if (count > 1) binary_sort(items, 0, count, 0);
        return;
    }

    usz[MAX_ITEMS] run_base;
    usz[MAX_ITEMS] run_lengths;
    usz stack_size = 0;
    usz min_run = min_run_length(count);
    usz start = 0;
    usz remaining = count;
    do {
        usz run_length = count_run_and_make_ascending(items, start, count);
        if (run_length < min_run) {
            usz force = min_run < remaining ? min_run : remaining;
            binary_sort(items, start, start + force, start + run_length);
            run_length = force;
        }
        run_base[stack_size] = start;
        run_lengths[stack_size] = run_length;
        stack_size++;
        merge_collapse(items, &run_base[0], &run_lengths[0], &stack_size);
        start += run_length;
        remaining -= run_length;
    } while (remaining != 0);
    merge_force_collapse(items, &run_base[0], &run_lengths[0], &stack_size);
}

fn long tim_sorter_benchmark(long* input, usz length) @export("tim_sorter_benchmark") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_ITEMS) return -1;
    usz count = (usz)input[0];
    if (length != 1 + 2 * count) return -1;

    Item[MAX_ITEMS] items;
    bool[MAX_ITEMS] seen = {};
    for (usz index = 0; index < count; index++) {
        long key = input[1 + 2 * index];
        long item_id = input[2 + 2 * index];
        if (key < -1000 || key > 1000 || item_id < 0 || item_id >= (long)count) return -1;
        if (seen[(usz)item_id]) return -1;
        seen[(usz)item_id] = true;
        items[index] = Item{key, item_id};
    }

    tim_sort(&items[0], count);
    long checksum = 0;
    for (usz index = 0; index < count; index++) {
        long token = (items[index].key + 1000) * 513 + items[index].item_id + 1;
        checksum = (checksum * HASH_MULTIPLIER + token) % HASH_MODULUS;
    }
    return checksum;
}

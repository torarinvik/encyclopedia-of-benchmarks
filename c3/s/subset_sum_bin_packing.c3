module subset_sum_bin_packing;

const usz MAX_ITEMS = 16;
const usz MAX_CAPACITY = 32;
const usz MAX_INPUT_LENGTH = 19;
const usz DP_STRIDE = MAX_CAPACITY + 1;

fn long subset_sum_bin_packing(long* input, usz length) @export("subset_sum_bin_packing") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long raw_count = input[0];
    long raw_capacity = input[1];
    if (raw_count < 1 || raw_count > (long)MAX_ITEMS ||
        raw_capacity < 1 || raw_capacity > (long)MAX_CAPACITY) return -1;
    usz count = (usz)raw_count;
    usz capacity = (usz)raw_capacity;
    if (length != 2 + count) return -1;

    long[MAX_ITEMS] remaining_size = {0};
    usz[MAX_ITEMS] remaining_item = {0};
    long[MAX_ITEMS] assigned_bin = {0};
    for (usz i = 0; i < count; i++) {
        long size = input[2 + i];
        if (size < 1 || size > raw_capacity) return -1;
        remaining_size[i] = size;
        remaining_item[i] = i;
    }

    usz remaining_count = count;
    long bin_count = 0;
    while (remaining_count > 0) {
        bool[MAX_ITEMS + 1][DP_STRIDE] reachable = {};
        reachable[remaining_count][0] = true;
        usz i = remaining_count;
        while (i > 0) {
            i--;
            usz size = (usz)remaining_size[i];
            for (usz sum = 0; sum <= capacity; sum++) {
                reachable[i][sum] = reachable[i + 1][sum];
                if (sum >= size && reachable[i + 1][sum - size])
                    reachable[i][sum] = true;
            }
        }

        usz target = capacity;
        while (target > 0 && !reachable[0][target]) target--;
        bool[MAX_ITEMS] selected = {};
        usz needed = target;
        for (usz item = 0; item < remaining_count; item++) {
            usz size = (usz)remaining_size[item];
            if (size <= needed && reachable[item + 1][needed - size]) {
                selected[item] = true;
                needed -= size;
                assigned_bin[remaining_item[item]] = bin_count;
            }
        }

        usz survivors = 0;
        for (usz item = 0; item < remaining_count; item++) {
            if (!selected[item]) {
                remaining_size[survivors] = remaining_size[item];
                remaining_item[survivors] = remaining_item[item];
                survivors++;
            }
        }
        remaining_count = survivors;
        bin_count++;
    }

    long checksum = bin_count * 10000;
    for (usz i = 0; i < count; i++)
        checksum += (long)(i + 1) * (assigned_bin[i] + 1);
    return checksum;
}

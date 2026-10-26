module orthogonal_range_reporting_2d;

const MAX_POINTS = 8;
const MAX_QUERIES = 8;
const MAX_INPUT_LENGTH = 50;
const BASE = 8;
const MAX_OUTPUT_WORDS = 73;

fn bool point_before(usz left, usz right, long* xs, long* ys) {
    return xs[left] < xs[right] || (xs[left] == xs[right] &&
        (ys[left] < ys[right] || (ys[left] == ys[right] && left < right)));
}

fn usz lower_x(usz* order, usz n, long* xs, long bound) {
    usz low = 0, high = n;
    while (low < high) {
        usz middle = low + (high - low) / 2;
        if (xs[order[middle]] < bound) low = middle + 1;
        else high = middle;
    }
    return low;
}

fn usz upper_x(usz* order, usz n, long* xs, long bound) {
    usz low = 0, high = n;
    while (low < high) {
        usz middle = low + (high - low) / 2;
        if (xs[order[middle]] <= bound) low = middle + 1;
        else high = middle;
    }
    return low;
}

fn usz report_node(usz node, usz* tree_ids, usz* tree_size, long* ys,
    long y_low, long y_high, usz* hits, usz offset) {
    usz low = 0, high = tree_size[node];
    while (low < high) {
        usz middle = low + (high - low) / 2;
        if (ys[tree_ids[node * MAX_POINTS + middle]] < y_low) low = middle + 1;
        else high = middle;
    }
    usz first = low;
    high = tree_size[node];
    while (low < high) {
        usz middle = low + (high - low) / 2;
        if (ys[tree_ids[node * MAX_POINTS + middle]] <= y_high) low = middle + 1;
        else high = middle;
    }
    for (usz index = first; index < low; index++) hits[offset + index - first] = tree_ids[node * MAX_POINTS + index];
    return low - first;
}

fn void sort_ids(usz* ids, usz count) {
    for (usz index = 1; index < count; index++) {
        usz item = ids[index], position = index;
        while (position > 0 && ids[position - 1] > item) {
            ids[position] = ids[position - 1];
            position--;
        }
        ids[position] = item;
    }
}

fn long orthogonal_range_reporting_2d(long* input, usz length, char* output, usz capacity) @export("orthogonal_range_reporting_2d") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_POINTS || input[1] < 1 || input[1] > MAX_QUERIES) return -1;
    usz n = (usz)input[0], q = (usz)input[1];
    if (length != 2 + 2 * n + 4 * q) return -1;

    long[MAX_POINTS] xs, ys;
    for (usz point = 0; point < n; point++) {
        xs[point] = input[2 + 2 * point];
        ys[point] = input[3 + 2 * point];
        if (xs[point] < 0 || xs[point] > 15 || ys[point] < 0 || ys[point] > 15) return -1;
        for (usz earlier = 0; earlier < point; earlier++) {
            if (xs[earlier] == xs[point] && ys[earlier] == ys[point]) return -1;
        }
    }
    long[MAX_QUERIES][4] queries;
    usz start = 2 + 2 * n;
    for (usz query = 0; query < q; query++) {
        for (usz item = 0; item < 4; item++) queries[query][item] = input[start + 4 * query + item];
        if (queries[query][0] < 0 || queries[query][0] > queries[query][1] || queries[query][1] > 15 ||
            queries[query][2] < 0 || queries[query][2] > queries[query][3] || queries[query][3] > 15) return -1;
    }

    usz[MAX_POINTS] order;
    for (usz point = 0; point < n; point++) order[point] = point;
    for (usz index = 1; index < n; index++) {
        usz item = order[index], position = index;
        while (position > 0 && point_before(item, order[position - 1], &xs[0], &ys[0])) {
            order[position] = order[position - 1];
            position--;
        }
        order[position] = item;
    }
    usz[128] tree_ids;
    usz[16] tree_size;
    for (usz tree_node = 0; tree_node < 16; tree_node++) tree_size[tree_node] = 0;
    for (usz rank = 0; rank < n; rank++) {
        tree_ids[(BASE + rank) * MAX_POINTS] = order[rank];
        tree_size[BASE + rank] = 1;
    }
    usz node = BASE - 1;
    while (node > 0) {
        usz left = 0, right = 0;
        usz left_node = node * 2, right_node = node * 2 + 1;
        while (left < tree_size[left_node] || right < tree_size[right_node]) {
            usz chosen;
            bool take_left = right >= tree_size[right_node];
            if (!take_left && left < tree_size[left_node]) {
                usz left_id = tree_ids[left_node * MAX_POINTS + left];
                usz right_id = tree_ids[right_node * MAX_POINTS + right];
                take_left = ys[left_id] < ys[right_id] || (ys[left_id] == ys[right_id] && left_id < right_id);
            }
            if (take_left) chosen = tree_ids[left_node * MAX_POINTS + left++];
            else chosen = tree_ids[right_node * MAX_POINTS + right++];
            tree_ids[node * MAX_POINTS + tree_size[node]++] = chosen;
        }
        node--;
    }

    long[MAX_OUTPUT_WORDS] words;
    usz cursor = 0;
    words[cursor++] = (long)q;
    for (usz query = 0; query < q; query++) {
        usz left = lower_x(&order[0], n, &xs[0], queries[query][0]) + BASE;
        usz right = upper_x(&order[0], n, &xs[0], queries[query][1]) + BASE;
        usz[MAX_POINTS] hits;
        usz hit_count = 0;
        while (left < right) {
            if ((left & 1) != 0) {
                hit_count += report_node(left, &tree_ids[0], &tree_size[0], &ys[0], queries[query][2], queries[query][3], &hits[0], hit_count);
                left++;
            }
            if ((right & 1) != 0) {
                right--;
                hit_count += report_node(right, &tree_ids[0], &tree_size[0], &ys[0], queries[query][2], queries[query][3], &hits[0], hit_count);
            }
            left /= 2;
            right /= 2;
        }
        sort_ids(&hits[0], hit_count);
        words[cursor++] = (long)hit_count;
        for (usz index = 0; index < hit_count; index++) words[cursor++] = (long)hits[index];
    }
    usz output_bytes = 8 * cursor;
    if (output == null || capacity < output_bytes) return -2;
    for (usz word = 0; word < cursor; word++) {
        ulong bits = (ulong)words[word];
        for (usz byte = 0; byte < 8; byte++) {
            output[word * 8 + byte] = (char)(bits & 255);
            bits >>= 8;
        }
    }
    return (long)output_bytes;
}

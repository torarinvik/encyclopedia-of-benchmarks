module mo_with_modifications;

const usz MAX_N = 64;
const usz MAX_Q = 64;
const usz MAX_INPUT_LENGTH = 2 + MAX_N + 3 * MAX_Q;

struct MoQuery { int left; int right; int time; int index; }
struct MoUpdate { int position; int old_value; int new_value; }

fn bool query_before(MoQuery* a, MoQuery* b, int block_size) {
    int a_left_block = a.left / block_size;
    int b_left_block = b.left / block_size;
    if (a_left_block != b_left_block) return a_left_block < b_left_block;
    int a_right_block = a.right / block_size;
    int b_right_block = b.right / block_size;
    if (a_right_block != b_right_block)
        return (a_left_block & 1) != 0 ? a_right_block > b_right_block
                                      : a_right_block < b_right_block;
    if (a.time != b.time)
        return ((a_left_block + a_right_block) & 1) != 0 ? a.time > b.time
                                                        : a.time < b.time;
    if (a.right != b.right)
        return (a_left_block & 1) != 0 ? a.right > b.right : a.right < b.right;
    return a.index < b.index;
}

fn void apply_update(MoUpdate* update, bool forward, int* values, int left, int right,
                     int* frequency, int* distinct) {
    int from = forward ? update.old_value : update.new_value;
    int to = forward ? update.new_value : update.old_value;
    if (left <= update.position && update.position <= right) {
        frequency[from]--;
        if (frequency[from] == 0) distinct[0]--;
        if (frequency[to] == 0) distinct[0]++;
        frequency[to]++;
    }
    values[update.position] = to;
}

fn long mo_with_modifications(long* input, usz length)
        @export("mo_with_modifications") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long raw_n = input[0];
    long raw_q = input[1];
    if (raw_n < 1 || raw_n > (long)MAX_N || raw_q < 0 || raw_q > (long)MAX_Q) return -1;
    int n = (int)raw_n;
    int operation_count = (int)raw_q;
    if (length != 2 + (usz)n + 3 * (usz)operation_count) return -1;

    int[MAX_N] values = {};
    int[MAX_N] simulated = {};
    for (int i = 0; i < n; i++) {
        long value = input[2 + i];
        if (value < 0 || value > 15) return -1;
        values[i] = (int)value;
        simulated[i] = (int)value;
    }

    MoUpdate[MAX_Q] updates = {};
    MoQuery[MAX_Q] queries = {};
    int update_count = 0;
    int query_count = 0;
    usz cursor = 2 + (usz)n;
    for (int i = 0; i < operation_count; i++) {
        long operation = input[cursor++];
        long first = input[cursor++];
        long second = input[cursor++];
        if (operation == 0) {
            if (first < 0 || first >= n || second < 0 || second > 15) return -1;
            int position = (int)first;
            updates[update_count].position = position;
            updates[update_count].old_value = simulated[position];
            updates[update_count].new_value = (int)second;
            simulated[position] = (int)second;
            update_count++;
        } else if (operation == 1) {
            if (first < 0 || second < first || second >= n) return -1;
            queries[query_count].left = (int)first;
            queries[query_count].right = (int)second;
            queries[query_count].time = update_count;
            queries[query_count].index = query_count;
            query_count++;
        } else return -1;
    }

    int block_size = 1;
    while (block_size * block_size * block_size < n * n) block_size++;
    for (int i = 1; i < query_count; i++) {
        MoQuery item = queries[i];
        int j = i;
        while (j > 0 && query_before(&item, &queries[j - 1], block_size)) {
            queries[j] = queries[j - 1];
            j--;
        }
        queries[j] = item;
    }

    int[MAX_Q] answers = {};
    int[16] frequency = {};
    int distinct = 0;
    int current_left = 0;
    int current_right = -1;
    int current_time = 0;
    for (int i = 0; i < query_count; i++) {
        MoQuery query = queries[i];
        while (current_time < query.time) {
            apply_update(&updates[current_time], true, &values[0], current_left,
                         current_right, &frequency[0], &distinct);
            current_time++;
        }
        while (current_time > query.time) {
            current_time--;
            apply_update(&updates[current_time], false, &values[0], current_left,
                         current_right, &frequency[0], &distinct);
        }
        while (current_left > query.left) {
            int value = values[--current_left];
            if (frequency[value]++ == 0) distinct++;
        }
        while (current_right < query.right) {
            int value = values[++current_right];
            if (frequency[value]++ == 0) distinct++;
        }
        while (current_left < query.left) {
            int value = values[current_left++];
            if (--frequency[value] == 0) distinct--;
        }
        while (current_right > query.right) {
            int value = values[current_right--];
            if (--frequency[value] == 0) distinct--;
        }
        answers[query.index] = distinct;
    }

    long checksum = 0;
    for (int i = 0; i < query_count; i++) checksum += (long)(i + 1) * (answers[i] + 1);
    return checksum;
}

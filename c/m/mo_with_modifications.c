#include <stddef.h>
#include <stdint.h>

#define MO_MOD_MAX_N 64
#define MO_MOD_MAX_Q 64
#define MO_MOD_MAX_LENGTH (2 + MO_MOD_MAX_N + 3 * MO_MOD_MAX_Q)

typedef struct {
    int left;
    int right;
    int time;
    int index;
} MoQuery;

typedef struct {
    int position;
    int old_value;
    int new_value;
} MoUpdate;

static int mo_query_before(const MoQuery *a, const MoQuery *b, int block_size) {
    const int a_left_block = a->left / block_size;
    const int b_left_block = b->left / block_size;
    if (a_left_block != b_left_block) return a_left_block < b_left_block;

    const int a_right_block = a->right / block_size;
    const int b_right_block = b->right / block_size;
    if (a_right_block != b_right_block)
        return (a_left_block & 1) ? a_right_block > b_right_block
                                  : a_right_block < b_right_block;

    if (a->time != b->time)
        return ((a_left_block + a_right_block) & 1) ? a->time > b->time
                                                    : a->time < b->time;
    if (a->right != b->right)
        return (a_left_block & 1) ? a->right > b->right : a->right < b->right;
    return a->index < b->index;
}

static void mo_apply_update(const MoUpdate *update, int forward, int *values,
                            int left, int right, int *frequency, int *distinct) {
    const int from = forward ? update->old_value : update->new_value;
    const int to = forward ? update->new_value : update->old_value;
    if (left <= update->position && update->position <= right) {
        if (--frequency[from] == 0) --*distinct;
        if (frequency[to]++ == 0) ++*distinct;
    }
    values[update->position] = to;
}

int64_t mo_with_modifications(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MO_MOD_MAX_LENGTH) return -1;
    const int64_t raw_n = input[0];
    const int64_t raw_q = input[1];
    if (raw_n < 1 || raw_n > MO_MOD_MAX_N || raw_q < 0 || raw_q > MO_MOD_MAX_Q)
        return -1;
    const int n = (int)raw_n;
    const int operation_count = (int)raw_q;
    if (length != (size_t)(2 + n + 3 * operation_count)) return -1;

    int values[MO_MOD_MAX_N];
    int simulated[MO_MOD_MAX_N];
    for (int i = 0; i < n; ++i) {
        const int64_t value = input[2 + i];
        if (value < 0 || value > 15) return -1;
        values[i] = simulated[i] = (int)value;
    }

    MoUpdate updates[MO_MOD_MAX_Q];
    MoQuery queries[MO_MOD_MAX_Q];
    int update_count = 0;
    int query_count = 0;
    size_t cursor = (size_t)(2 + n);
    for (int i = 0; i < operation_count; ++i) {
        const int64_t operation = input[cursor++];
        const int64_t first = input[cursor++];
        const int64_t second = input[cursor++];
        if (operation == 0) {
            if (first < 0 || first >= n || second < 0 || second > 15) return -1;
            const int position = (int)first;
            updates[update_count++] = (MoUpdate){position, simulated[position], (int)second};
            simulated[position] = (int)second;
        } else if (operation == 1) {
            if (first < 0 || second < first || second >= n) return -1;
            queries[query_count] = (MoQuery){(int)first, (int)second, update_count, query_count};
            ++query_count;
        } else {
            return -1;
        }
    }

    int block_size = 1;
    while (block_size * block_size * block_size < n * n) ++block_size;
    for (int i = 1; i < query_count; ++i) {
        const MoQuery item = queries[i];
        int j = i;
        while (j > 0 && mo_query_before(&item, &queries[j - 1], block_size)) {
            queries[j] = queries[j - 1];
            --j;
        }
        queries[j] = item;
    }

    int answers[MO_MOD_MAX_Q] = {0};
    int frequency[16] = {0};
    int distinct = 0;
    int current_left = 0;
    int current_right = -1;
    int current_time = 0;
    for (int i = 0; i < query_count; ++i) {
        const MoQuery query = queries[i];
        while (current_time < query.time) {
            mo_apply_update(&updates[current_time], 1, values, current_left,
                            current_right, frequency, &distinct);
            ++current_time;
        }
        while (current_time > query.time) {
            --current_time;
            mo_apply_update(&updates[current_time], 0, values, current_left,
                            current_right, frequency, &distinct);
        }
        while (current_left > query.left) {
            const int value = values[--current_left];
            if (frequency[value]++ == 0) ++distinct;
        }
        while (current_right < query.right) {
            const int value = values[++current_right];
            if (frequency[value]++ == 0) ++distinct;
        }
        while (current_left < query.left) {
            const int value = values[current_left++];
            if (--frequency[value] == 0) --distinct;
        }
        while (current_right > query.right) {
            const int value = values[current_right--];
            if (--frequency[value] == 0) --distinct;
        }
        answers[query.index] = distinct;
    }

    int64_t checksum = 0;
    for (int i = 0; i < query_count; ++i)
        checksum += (int64_t)(i + 1) * (answers[i] + 1);
    return checksum;
}

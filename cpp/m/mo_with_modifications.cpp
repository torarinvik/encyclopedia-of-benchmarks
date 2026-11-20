#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 64;
constexpr int max_q = 64;
constexpr std::size_t max_input_length = 2 + max_n + 3 * max_q;

struct MoQuery {
    int left;
    int right;
    int time;
    int index;
};

struct MoUpdate {
    int position;
    int old_value;
    int new_value;
};

bool query_before(const MoQuery& a, const MoQuery& b, int block_size) noexcept {
    const int a_left_block = a.left / block_size;
    const int b_left_block = b.left / block_size;
    if (a_left_block != b_left_block) return a_left_block < b_left_block;

    const int a_right_block = a.right / block_size;
    const int b_right_block = b.right / block_size;
    if (a_right_block != b_right_block)
        return (a_left_block & 1) ? a_right_block > b_right_block
                                  : a_right_block < b_right_block;
    if (a.time != b.time)
        return ((a_left_block + a_right_block) & 1) ? a.time > b.time
                                                    : a.time < b.time;
    if (a.right != b.right)
        return (a_left_block & 1) ? a.right > b.right : a.right < b.right;
    return a.index < b.index;
}

void apply_update(const MoUpdate& update, bool forward, int* values, int left,
                  int right, int* frequency, int& distinct) noexcept {
    const int from = forward ? update.old_value : update.new_value;
    const int to = forward ? update.new_value : update.old_value;
    if (left <= update.position && update.position <= right) {
        if (--frequency[from] == 0) --distinct;
        if (frequency[to]++ == 0) ++distinct;
    }
    values[update.position] = to;
}
} // namespace

extern "C" std::int64_t mo_with_modifications(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const std::int64_t raw_n = input[0];
    const std::int64_t raw_q = input[1];
    if (raw_n < 1 || raw_n > max_n || raw_q < 0 || raw_q > max_q) return -1;
    const int n = static_cast<int>(raw_n);
    const int operation_count = static_cast<int>(raw_q);
    if (length != static_cast<std::size_t>(2 + n + 3 * operation_count)) return -1;

    int values[max_n]{};
    int simulated[max_n]{};
    for (int i = 0; i < n; ++i) {
        const std::int64_t value = input[2 + i];
        if (value < 0 || value > 15) return -1;
        values[i] = simulated[i] = static_cast<int>(value);
    }

    MoUpdate updates[max_q]{};
    MoQuery queries[max_q]{};
    int update_count = 0;
    int query_count = 0;
    std::size_t cursor = static_cast<std::size_t>(2 + n);
    for (int i = 0; i < operation_count; ++i) {
        const std::int64_t operation = input[cursor++];
        const std::int64_t first = input[cursor++];
        const std::int64_t second = input[cursor++];
        if (operation == 0) {
            if (first < 0 || first >= n || second < 0 || second > 15) return -1;
            const int position = static_cast<int>(first);
            updates[update_count++] = {position, simulated[position], static_cast<int>(second)};
            simulated[position] = static_cast<int>(second);
        } else if (operation == 1) {
            if (first < 0 || second < first || second >= n) return -1;
            queries[query_count] = {static_cast<int>(first), static_cast<int>(second),
                                    update_count, query_count};
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
        while (j > 0 && query_before(item, queries[j - 1], block_size)) {
            queries[j] = queries[j - 1];
            --j;
        }
        queries[j] = item;
    }

    int answers[max_q]{};
    int frequency[16]{};
    int distinct = 0;
    int current_left = 0;
    int current_right = -1;
    int current_time = 0;
    for (int i = 0; i < query_count; ++i) {
        const MoQuery query = queries[i];
        while (current_time < query.time) {
            apply_update(updates[current_time], true, values, current_left,
                         current_right, frequency, distinct);
            ++current_time;
        }
        while (current_time > query.time) {
            --current_time;
            apply_update(updates[current_time], false, values, current_left,
                         current_right, frequency, distinct);
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

    std::int64_t checksum = 0;
    for (int i = 0; i < query_count; ++i)
        checksum += static_cast<std::int64_t>(i + 1) * (answers[i] + 1);
    return checksum;
}

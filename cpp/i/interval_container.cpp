#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_OPERATIONS = 24;
constexpr int RECORD_WIDTH = 3;
constexpr std::size_t MAX_INPUT_VALUES = 73;
constexpr int MAX_INTERVALS = 25;
constexpr int DOMAIN_END = 32;

struct Interval { int left = 0; int right = 0; };

void add_interval(Interval* items, int& count, int left, int right) {
    if (left == right) return;
    Interval next[MAX_INTERVALS]{};
    int out = 0;
    bool inserted = false;
    for (int i = 0; i < count; ++i) {
        const Interval current = items[i];
        if (current.right < left) next[out++] = current;
        else if (right < current.left) {
            if (!inserted) {
                next[out++] = {left, right};
                inserted = true;
            }
            next[out++] = current;
        } else {
            if (current.left < left) left = current.left;
            if (current.right > right) right = current.right;
        }
    }
    if (!inserted) next[out++] = {left, right};
    for (int i = 0; i < out; ++i) items[i] = next[i];
    count = out;
}

void remove_interval(Interval* items, int& count, int left, int right) {
    if (left == right) return;
    Interval next[MAX_INTERVALS + 1]{};
    int out = 0;
    for (int i = 0; i < count; ++i) {
        const Interval current = items[i];
        if (current.right <= left || current.left >= right) next[out++] = current;
        else {
            if (current.left < left) next[out++] = {current.left, left};
            if (current.right > right) next[out++] = {right, current.right};
        }
    }
    for (int i = 0; i < out; ++i) items[i] = next[i];
    count = out;
}

int covered_length(const Interval* items, int count) {
    int total = 0;
    for (int i = 0; i < count; ++i) total += items[i].right - items[i].left;
    return total;
}

bool valid_input(const std::int64_t* input, std::size_t length, int& count) {
    if (input == nullptr || length < 1 || length > MAX_INPUT_VALUES) return false;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS) return false;
    count = static_cast<int>(input[0]);
    if (length != 1 + static_cast<std::size_t>(count) * RECORD_WIDTH) return false;
    for (int i = 0; i < count; ++i) {
        const std::size_t offset = 1 + static_cast<std::size_t>(i) * RECORD_WIDTH;
        const std::int64_t opcode = input[offset];
        const std::int64_t left = input[offset + 1];
        const std::int64_t right = input[offset + 2];
        if (opcode < 0 || opcode > 1 || left < 0 || right < left || right > DOMAIN_END)
            return false;
    }
    return true;
}
} // namespace

extern "C" std::int64_t interval_container(const std::int64_t* input,
                                             std::size_t length) {
    int operation_count = 0;
    if (!valid_input(input, length, operation_count)) return -1;
    Interval items[MAX_INTERVALS]{};
    int count = 0;
    std::int64_t checksum = 0;
    for (int i = 0; i < operation_count; ++i) {
        const std::size_t offset = 1 + static_cast<std::size_t>(i) * RECORD_WIDTH;
        const int opcode = static_cast<int>(input[offset]);
        const int left = static_cast<int>(input[offset + 1]);
        const int right = static_cast<int>(input[offset + 2]);
        if (opcode == 0) add_interval(items, count, left, right);
        else remove_interval(items, count, left, right);
        checksum += static_cast<std::int64_t>(i + 1) * covered_length(items, count);
    }
    return checksum;
}

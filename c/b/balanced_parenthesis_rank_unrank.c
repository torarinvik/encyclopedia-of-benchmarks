#include <stddef.h>
#include <stdint.h>

#define MAX_PAIRS 10
#define MAX_INPUT_LENGTH 22
#define WAYS_STRIDE 11
#define WAYS_COUNT 231

int64_t balanced_parenthesis_rank_unrank(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t mode = input[0], pairs_value = input[1];
    if (pairs_value < 1 || pairs_value > MAX_PAIRS) return -1;
    const size_t pairs = (size_t)pairs_value, sequence_length = 2 * pairs;
    if (mode == 0) {
        if (length != 2 + sequence_length) return -1;
        int balance = 0;
        for (size_t i = 0; i < sequence_length; ++i) {
            const int64_t symbol = input[2 + i];
            if (symbol != 0 && symbol != 1) return -1;
            balance += symbol == 0 ? 1 : -1;
            if (balance < 0) return -1;
        }
        if (balance != 0) return -1;
    } else if (mode == 1) {
        if (length != 3) return -1;
    } else {
        return -1;
    }

    int64_t ways[WAYS_COUNT] = {0};
    ways[0] = 1;
    for (size_t remaining = 1; remaining <= sequence_length; ++remaining) {
        for (size_t balance = 0; balance <= pairs; ++balance) {
            int64_t count = 0;
            if (balance < pairs) count += ways[(remaining - 1) * WAYS_STRIDE + balance + 1];
            if (balance > 0) count += ways[(remaining - 1) * WAYS_STRIDE + balance - 1];
            ways[remaining * WAYS_STRIDE + balance] = count;
        }
    }

    if (mode == 0) {
        int64_t rank = 0;
        size_t balance = 0;
        for (size_t i = 0; i < sequence_length; ++i) {
            const int64_t symbol = input[2 + i];
            const size_t remaining = sequence_length - i - 1;
            if (symbol == 1 && balance < pairs)
                rank += ways[remaining * WAYS_STRIDE + balance + 1];
            balance = symbol == 0 ? balance + 1 : balance - 1;
        }
        return rank;
    }

    int64_t rank = input[2];
    if (rank < 0 || rank >= ways[sequence_length * WAYS_STRIDE]) return -1;
    size_t balance = 0;
    uint64_t code = 0;
    for (size_t i = 0; i < sequence_length; ++i) {
        const size_t remaining = sequence_length - i - 1;
        const int64_t opening_count = balance < pairs
            ? ways[remaining * WAYS_STRIDE + balance + 1] : 0;
        int64_t symbol;
        if (rank < opening_count) {
            symbol = 0;
            ++balance;
        } else {
            rank -= opening_count;
            symbol = 1;
            --balance;
        }
        code = (code << 1) | (uint64_t)symbol;
    }
    return (int64_t)code;
}

/* Fenwick frequency selection by binary lifting over prefix blocks. */
#include <stddef.h>
#include <stdint.h>

int64_t fenwick_kth(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > 163) return -1;
    if (input[0] < 1 || input[0] > 64 || input[1] < 0 || input[1] > 32) return -1;
    const size_t n = (size_t)input[0];
    const size_t q = (size_t)input[1];
    if (length != 2 + n + 3 * q) return -1;

    int64_t frequency[64] = {0};
    int64_t tree[65] = {0};
    int64_t total = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = input[2 + i];
        if (value < 0 || value > 1000000) return -1;
        frequency[i] = value;
        total += value;
        const size_t index = i + 1;
        tree[index] += value;
        const size_t parent = index + (index & (0 - index));
        if (parent <= n) tree[parent] += tree[index];
    }

    int64_t result = 0;
    size_t query_number = 0;
    size_t cursor = 2 + n;
    for (size_t operation = 0; operation < q; ++operation) {
        const int64_t opcode = input[cursor];
        const int64_t first = input[cursor + 1];
        const int64_t second = input[cursor + 2];
        cursor += 3;
        if (opcode == 0) {
            if (first < 0 || first >= (int64_t)n || second < -1000000 || second > 1000000) return -1;
            const size_t position = (size_t)first;
            const int64_t updated = frequency[position] + second;
            if (updated < 0 || updated > 1000000) return -1;
            frequency[position] = updated;
            total += second;
            size_t index = position + 1;
            while (index <= n) {
                tree[index] += second;
                index += index & (0 - index);
            }
        } else if (opcode == 1) {
            if (second != 0) return -1;
            int64_t answer = -1;
            if (first > 0 && first <= total) {
                size_t index = 0;
                size_t step = 1;
                while (step <= n / 2) step *= 2;
                int64_t rank = first;
                while (step != 0) {
                    const size_t candidate = index + step;
                    if (candidate <= n && tree[candidate] < rank) {
                        index = candidate;
                        rank -= tree[candidate];
                    }
                    step /= 2;
                }
                answer = (int64_t)index;
            }
            result += (int64_t)(query_number + 1) * (answer + 1);
            ++query_number;
        } else {
            return -1;
        }
    }
    return result;
}

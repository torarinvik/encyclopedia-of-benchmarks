/* Fenwick frequency selection by binary lifting over prefix blocks. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t fenwick_kth(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 3 || length > 163) return -1;
    if (input[0] < 1 || input[0] > 64 || input[1] < 0 || input[1] > 32) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto q = static_cast<std::size_t>(input[1]);
    if (length != 2 + n + 3 * q) return -1;

    std::int64_t frequency[64]{};
    std::int64_t tree[65]{};
    std::int64_t total = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = input[2 + i];
        if (value < 0 || value > 1000000) return -1;
        frequency[i] = value;
        total += value;
        const std::size_t index = i + 1;
        tree[index] += value;
        const std::size_t parent = index + (index & (0 - index));
        if (parent <= n) tree[parent] += tree[index];
    }

    std::int64_t result = 0;
    std::size_t query_number = 0;
    std::size_t cursor = 2 + n;
    for (std::size_t operation = 0; operation < q; ++operation) {
        const auto opcode = input[cursor];
        const auto first = input[cursor + 1];
        const auto second = input[cursor + 2];
        cursor += 3;
        if (opcode == 0) {
            if (first < 0 || first >= static_cast<std::int64_t>(n) || second < -1000000 || second > 1000000) return -1;
            const auto position = static_cast<std::size_t>(first);
            const auto updated = frequency[position] + second;
            if (updated < 0 || updated > 1000000) return -1;
            frequency[position] = updated;
            total += second;
            std::size_t index = position + 1;
            while (index <= n) {
                tree[index] += second;
                index += index & (0 - index);
            }
        } else if (opcode == 1) {
            if (second != 0) return -1;
            std::int64_t answer = -1;
            if (first > 0 && first <= total) {
                std::size_t index = 0;
                std::size_t step = 1;
                while (step <= n / 2) step *= 2;
                auto rank = first;
                while (step != 0) {
                    const auto candidate = index + step;
                    if (candidate <= n && tree[candidate] < rank) {
                        index = candidate;
                        rank -= tree[candidate];
                    }
                    step /= 2;
                }
                answer = static_cast<std::int64_t>(index);
            }
            result += static_cast<std::int64_t>(query_number + 1) * (answer + 1);
            ++query_number;
        } else {
            return -1;
        }
    }
    return result;
}

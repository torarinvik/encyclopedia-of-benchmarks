#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 8, MAX_ROUNDS = 32, MAX_INPUT = 275, MAX_OUTPUT = 64;
void put64(std::uint8_t* output, std::size_t position, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (8U * byte));
}
}

extern "C" std::int64_t list_ranking_random_mate(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 5 || length > MAX_INPUT) return -1;
    const auto n64 = input[0], head64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MAX_N) || head64 < 0 || head64 >= n64)
        return -1;
    const auto n = static_cast<std::size_t>(n64), head = static_cast<std::size_t>(head64);
    if (length < 3 + 2*n) return -1;
    const auto rounds64 = input[2 + 2*n];
    if (rounds64 < 0 || rounds64 > static_cast<std::int64_t>(MAX_ROUNDS) ||
        length != 3 + 2*n + static_cast<std::size_t>(rounds64)*n) return -1;
    const auto rounds = static_cast<std::size_t>(rounds64);
    std::int64_t weight[MAX_N]{}, successor[MAX_N]{};
    std::size_t indegree[MAX_N]{}, tails = 0;
    for (std::size_t index = 0; index < n; ++index) {
        weight[index] = input[2 + index]; successor[index] = input[2 + n + index];
        if (weight[index] < 1 || weight[index] > 10000 || successor[index] < -1 || successor[index] >= n64)
            return -1;
        if (successor[index] == -1) ++tails;
        else if (++indegree[static_cast<std::size_t>(successor[index])] > 1) return -1;
    }
    if (tails != 1 || indegree[head] != 0) return -1;
    const auto coin_start = 3 + 2*n;
    for (std::size_t index = 0; index < rounds*n; ++index)
        if (input[coin_start + index] < 0 || input[coin_start + index] > 1) return -1;

    bool seen[MAX_N]{};
    std::size_t path_length = 0;
    auto node = head64;
    while (node != -1) {
        const auto index = static_cast<std::size_t>(node);
        if (seen[index] || path_length == n) return -1;
        seen[index] = true; ++path_length; node = successor[index];
    }
    if (path_length != n) return -1;

    bool active[MAX_N]; int removal_round[MAX_N];
    for (std::size_t index = 0; index < n; ++index) { active[index] = true; removal_round[index] = -1; }
    for (std::size_t round = 0; round < rounds && successor[head] != -1; ++round) {
        std::int64_t old_successor[MAX_N], old_weight[MAX_N]; bool remove[MAX_N]{};
        for (std::size_t index = 0; index < n; ++index) {
            old_successor[index] = successor[index]; old_weight[index] = weight[index];
        }
        const auto coin_offset = coin_start + round*n;
        for (std::size_t index = 0; index < n; ++index) {
            const auto target = old_successor[index];
            if (active[index] && target != -1 && input[coin_offset + index] == 0 &&
                input[coin_offset + static_cast<std::size_t>(target)] == 1) {
                remove[static_cast<std::size_t>(target)] = true;
                removal_round[static_cast<std::size_t>(target)] = static_cast<int>(round);
            }
        }
        for (std::size_t index = 0; index < n; ++index) {
            const auto target = old_successor[index];
            if (active[index] && target != -1 && remove[static_cast<std::size_t>(target)]) {
                weight[index] = old_weight[index] + old_weight[static_cast<std::size_t>(target)];
                successor[index] = old_successor[static_cast<std::size_t>(target)];
            }
        }
        for (std::size_t index = 0; index < n; ++index) if (remove[index]) active[index] = false;
    }
    if (successor[head] != -1) return -1;

    std::int64_t rank[MAX_N]{};
    for (std::size_t index = 0; index < n; ++index) rank[index] = weight[index];
    for (std::size_t round = rounds; round > 0; --round)
        for (std::size_t index = 0; index < n; ++index)
            if (removal_round[index] == static_cast<int>(round - 1) && successor[index] != -1)
                rank[index] += rank[static_cast<std::size_t>(successor[index])];

    const auto output_bytes = 8*n;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::uint8_t staged[MAX_OUTPUT]{};
    for (std::size_t index = 0; index < n; ++index) put64(staged, 8*index, rank[index]);
    for (std::size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_bytes);
}

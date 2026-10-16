#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" int64_t dynamic_coin_change_solver(const int64_t* input, std::size_t length) {
    if (input == nullptr || length < 3 || length > 11) return -1;
    const int64_t amount = input[0], count_value = input[1];
    if (amount < 1 || amount > 18 || count_value < 1 || count_value > 9 || length != std::size_t(count_value + 2)) return -1;
    std::array<int, 9> coins{};
    bool has_one = false;
    for (int i = 0; i < count_value; ++i) {
        if (input[i + 2] < 1 || input[i + 2] > 9) return -1;
        coins[i] = static_cast<int>(input[i + 2]); has_one |= coins[i] == 1;
        for (int j = 0; j < i; ++j) if (coins[i] == coins[j]) return -1;
    }
    if (!has_one) return -1;
    std::sort(coins.begin(), coins.begin() + count_value, std::greater<int>());
    std::array<std::array<int, 9>, 19> changes{};
    std::array<int, 19> sizes{};
    for (int value = 1; value <= amount; ++value)
        for (int i = 0; i < count_value; ++i) if (coins[i] <= value) changes[value][sizes[value]++] = value - coins[i];
    int64_t code = 0, current = amount;
    for (int step = 0; step < 18; ++step) {
        int64_t next = std::numeric_limits<int32_t>::max();
        int min_change = std::numeric_limits<int32_t>::max();
        for (int i = 0; i < sizes[current]; ++i) {
            const int change = changes[current][i];
            if (change == 0) { next = 0; break; }
            int minimum = std::numeric_limits<int>::max();
            for (int j = 0; j < sizes[change]; ++j) minimum = std::min(minimum, changes[change][j]);
            if (minimum < min_change) { min_change = minimum; next = change; }
        }
        if (next == std::numeric_limits<int32_t>::max()) return -1;
        code = code * 10 + current - next;
        if (next == 0) return code;
        current = next;
    }
    return -1;
}

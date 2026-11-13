#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <queue>
#include <tuple>
#include <vector>

extern "C" std::int64_t multiprobe_lsh_probe_sequence(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 4 || length > 7 || input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 1000) return -1;
    const int m = static_cast<int>(input[0]), width = static_cast<int>(input[1]);
    int limit = 1;
    for (int i = 0; i < m; ++i) limit *= 3;
    if (length != static_cast<std::size_t>(3+m) || input[2] < 0 || input[2] >= limit) return -1;
    const int count = static_cast<int>(input[2]);
    using Choice = std::tuple<int, int, int>;
    std::array<Choice, 8> choices{};
    for (int i = 0; i < m; ++i) {
        if (input[3+i] < 0 || input[3+i] > width) return -1;
        const int low = static_cast<int>(input[3+i]);
        choices[2*i] = {low, i, -1}; choices[2*i+1] = {width-low, i, 1};
    }
    std::sort(choices.begin(), choices.begin()+2*m);
    using Item = std::tuple<int, int, int>;
    auto entry = [&](int mask) {
        int score = 0, bits = 0;
        for (int i = 0; i < 2*m; ++i) if (mask & (1 << i)) {
            int d = std::get<0>(choices[i]); score += d*d; ++bits;
        }
        return Item{score, bits, mask};
    };
    std::priority_queue<Item, std::vector<Item>, std::greater<Item>> heap;
    heap.push(entry(1));
    std::array<std::uint8_t, 80> result{};
    int emitted = 0;
    while (emitted < count) {
        int mask = std::get<2>(heap.top()); heap.pop();
        int top = 0;
        while ((1 << (top+1)) <= mask) ++top;
        if (top+1 < 2*m) {
            heap.push(entry((mask ^ (1 << top)) | (1 << (top+1))));
            heap.push(entry(mask | (1 << (top+1))));
        }
        int seen = 0; bool valid = true;
        for (int i = 0; i < 2*m; ++i) if (mask & (1 << i)) {
            int bit = 1 << std::get<1>(choices[i]);
            if (seen & bit) { valid = false; break; }
            seen |= bit;
        }
        if (valid) result[emitted++] = static_cast<std::uint8_t>(mask);
    }
    if (!output || capacity < static_cast<std::size_t>(count)) return -2;
    std::copy_n(result.begin(), count, output);
    return count;
}

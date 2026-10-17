#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_ops = 32, max_input = 98;
std::size_t find_key(const std::int64_t *keys, std::size_t count, std::int64_t key) {
    for (std::size_t i = 0; i < count; ++i) if (keys[i] == key) return i;
    return count;
}
void swap_items(std::int64_t *keys, std::int64_t *priorities, std::size_t a, std::size_t b) {
    auto t = keys[a]; keys[a] = keys[b]; keys[b] = t;
    t = priorities[a]; priorities[a] = priorities[b]; priorities[b] = t;
}
void shift_up(std::int64_t *keys, std::int64_t *priorities, std::size_t i) {
    while (i) { const auto p = (i - 1) / 2; if (priorities[p] <= priorities[i]) break;
        swap_items(keys, priorities, p, i); i = p; }
}
void shift_down(std::int64_t *keys, std::int64_t *priorities, std::size_t n, std::size_t i) {
    while (2 * i + 1 < n) { const auto l = 2 * i + 1, r = l + 1; std::size_t c;
        if (priorities[l] < priorities[i] && (r >= n || priorities[l] < priorities[r])) c = l;
        else if (r < n && priorities[r] < priorities[i]) c = r; else break;
        swap_items(keys, priorities, i, c); i = c; }
}
}

extern "C" std::int64_t key_priority_queue(const std::int64_t *input, std::size_t length,
                                             std::uint8_t *output, std::size_t output_capacity) {
    if (!input || length < 1 || length > max_input || input[0] < 0 || input[0] > (std::int64_t)max_ops) return -1;
    std::int64_t keys[max_ops], priorities[max_ops], answers[max_ops];
    std::size_t n = 0, out_n = 0, pos = 1;
    for (std::size_t opi = 0; opi < (std::size_t)input[0]; ++opi) {
        if (pos >= length) return -1;
        const auto op = input[pos];
        if (op == 0 || op == 1) {
            if (pos + 2 >= length) return -1;
            const auto key = input[pos + 1], priority = input[pos + 2];
            if (key < -1000000000LL || key > 1000000000LL || priority < -1000000000LL || priority > 1000000000LL) return -1;
            pos += 3; const auto found = find_key(keys, n, key);
            if (op == 0) { if (found != n) return -1; keys[n] = key; priorities[n] = priority; shift_up(keys, priorities, n++); }
            else if (found == n) { keys[n] = key; priorities[n] = priority; shift_up(keys, priorities, n++); }
            else { priorities[found] = priority;
                if (found > 0 && priorities[(found - 1) / 2] > priority) shift_up(keys, priorities, found);
                else { const auto l = 2 * found + 1, r = l + 1;
                    if ((l < n && priorities[l] < priority) || (r < n && priorities[r] < priority)) shift_down(keys, priorities, n, found); }
            }
        } else if (op == 2) { ++pos; if (!n) return -1; swap_items(keys, priorities, 0, n - 1); answers[out_n++] = keys[--n]; if (n) shift_down(keys, priorities, n, 0); }
        else if (op == 3) { if (pos + 1 >= length) return -1; const auto key = input[pos + 1]; if (key < -1000000000LL || key > 1000000000LL) return -1; pos += 2; answers[out_n++] = find_key(keys, n, key) != n; }
        else if (op == 4) { ++pos; answers[out_n++] = n == 0; }
        else return -1;
    }
    if (pos != length) return -1;
    const auto bytes = out_n * sizeof(std::int64_t);
    if (!output || output_capacity < bytes) return -2;
    for (std::size_t i = 0; i < out_n; ++i) { const auto bits = static_cast<std::uint64_t>(answers[i]); for (std::size_t b = 0; b < 8; ++b) output[8*i+b] = static_cast<std::uint8_t>(bits >> (8*b)); }
    return static_cast<std::int64_t>(bytes);
}

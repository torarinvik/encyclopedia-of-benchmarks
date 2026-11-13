#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 8, L = 8, H = 17;
using Words = int[N][L];
bool palindrome(const Words& words, int id, int left, int right) {
    for (--right; left < right; ++left, --right) if (words[id][left] != words[id][right]) return false;
    return true;
}
std::int64_t encode(const Words& words, int id, int left, int right, bool reverse) {
    std::int64_t key = 1;
    if (reverse) { while (right > left) key = key * 5 + words[id][--right] + 1; }
    else for (int i = left; i < right; ++i) key = key * 5 + words[id][i] + 1;
    return key;
}
std::size_t slot_for(const std::int64_t* keys, std::int64_t key) {
    std::size_t slot = static_cast<std::size_t>(key % H);
    while (keys[slot] != 0 && keys[slot] != key) slot = (slot + 1) % H;
    return slot;
}
void mark(const std::int64_t* keys, const int* heads, const int* next, std::int64_t key,
          int fixed, bool fixed_right, bool found[N][N]) {
    const std::size_t slot = slot_for(keys, key);
    if (keys[slot] != key) return;
    for (int id = heads[slot]; id >= 0; id = next[id]) {
        if (id == fixed) continue;
        if (fixed_right) found[id][fixed] = true;
        else found[fixed][id] = true;
    }
}
}

extern "C" std::int64_t palindrome_pairs(const std::int64_t* input, std::size_t length,
                                           std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 1 || length > 74 || input[0] < 0 || input[0] > N) return -1;
    const int count = static_cast<int>(input[0]);
    Words words{}; int sizes[N]{}; std::size_t cursor = 1;
    for (int id = 0; id < count; ++id) {
        if (cursor >= length || input[cursor] < 0 || input[cursor] > L) return -1;
        sizes[id] = static_cast<int>(input[cursor++]);
        if (cursor + static_cast<std::size_t>(sizes[id]) > length) return -1;
        for (int k = 0; k < sizes[id]; ++k) {
            if (input[cursor] < 0 || input[cursor] >= 4) return -1;
            words[id][k] = static_cast<int>(input[cursor++]);
        }
    }
    if (cursor != length) return -1;
    std::int64_t keys[H]{}; int heads[H]; int next[N];
    for (int i = 0; i < H; ++i) heads[i] = -1;
    for (int i = 0; i < N; ++i) next[i] = -1;
    for (int id = 0; id < count; ++id) {
        const auto key = encode(words, id, 0, sizes[id], false);
        const auto slot = slot_for(keys, key);
        if (keys[slot] == 0) { keys[slot] = key; heads[slot] = id; }
        else { next[id] = heads[slot]; heads[slot] = id; }
    }
    bool found[N][N]{};
    for (int id = 0; id < count; ++id) for (int split = 0; split <= sizes[id]; ++split) {
        if (palindrome(words, id, 0, split)) mark(keys, heads, next, encode(words, id, split, sizes[id], true), id, true, found);
        if (palindrome(words, id, split, sizes[id])) mark(keys, heads, next, encode(words, id, 0, split, true), id, false, found);
    }
    std::uint8_t staged[N * (N - 1)]{}; std::size_t bytes = 0;
    for (int left = 0; left < count; ++left) for (int right = 0; right < count; ++right)
        if (left != right && found[left][right]) staged[bytes++] = static_cast<std::uint8_t>(left * N + right);
    if (!output || capacity < bytes) return -2;
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}

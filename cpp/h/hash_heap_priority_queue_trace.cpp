#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxBuckets = 8;
constexpr int kMaxOps = 64;
constexpr std::size_t kMaxWords = 132;
constexpr std::size_t kMaxBytes = 520;

struct Item { std::uint8_t key; std::uint8_t insertion; };
bool less(const Item& a, const Item& b) {
    return a.key < b.key || (a.key == b.key && a.insertion < b.insertion);
}
void push(std::array<std::array<Item, kMaxOps>, kMaxBuckets>& heaps,
          std::array<int, kMaxBuckets>& sizes, int bucket, Item item) {
    int child = sizes[bucket]++;
    heaps[bucket][child] = item;
    while (child > 0) {
        int parent = (child - 1) / 2;
        if (!less(heaps[bucket][child], heaps[bucket][parent])) break;
        auto tmp = heaps[bucket][child];
        heaps[bucket][child] = heaps[bucket][parent];
        heaps[bucket][parent] = tmp;
        child = parent;
    }
}
void pop(std::array<std::array<Item, kMaxOps>, kMaxBuckets>& heaps,
         std::array<int, kMaxBuckets>& sizes, int bucket) {
    int last = --sizes[bucket];
    if (last == 0) return;
    heaps[bucket][0] = heaps[bucket][last];
    int parent = 0;
    for (;;) {
        int left = parent * 2 + 1;
        if (left >= sizes[bucket]) break;
        int child = left;
        int right = left + 1;
        if (right < sizes[bucket] && less(heaps[bucket][right], heaps[bucket][left])) child = right;
        if (!less(heaps[bucket][child], heaps[bucket][parent])) break;
        auto tmp = heaps[bucket][child];
        heaps[bucket][child] = heaps[bucket][parent];
        heaps[bucket][parent] = tmp;
        parent = child;
    }
}
void write_i64(std::array<std::uint8_t, kMaxBytes>& out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (int i = 0; i < 8; ++i) out[at + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}

extern "C" std::int64_t hash_heap_priority_queue_trace(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > kMaxWords) return -1;
    const auto u = input[0], b = input[1], qv = input[2];
    if (u < 1 || u > 128 || b < 1 || b > 8 || b > u || qv < 0 || qv > kMaxOps) return -1;
    const int universe = static_cast<int>(u), bucket_count = static_cast<int>(b), q = static_cast<int>(qv);
    if (length != static_cast<std::size_t>(3 + 2 * q)) return -1;
    std::array<std::uint8_t, kMaxOps> opcodes{};
    std::array<std::uint8_t, kMaxOps> operands{};
    for (int i = 0; i < q; ++i) {
        const auto op = input[3 + 2 * i], arg = input[4 + 2 * i];
        if (op == 0) { if (arg < 0 || arg >= universe) return -1; }
        else if (op == 1 || op == 2) { if (arg != 0) return -1; }
        else return -1;
        opcodes[i] = static_cast<std::uint8_t>(op);
        operands[i] = static_cast<std::uint8_t>(arg);
    }
    std::array<std::array<Item, kMaxOps>, kMaxBuckets> heaps{};
    std::array<int, kMaxBuckets> sizes{};
    std::array<std::uint8_t, kMaxBytes> staged{};
    write_i64(staged, 0, q);
    for (int i = 0; i < q; ++i) {
        const auto at = static_cast<std::size_t>(i + 1) * 8;
        if (opcodes[i] == 0) {
            const int bucket = (static_cast<int>(operands[i]) * bucket_count) / universe;
            push(heaps, sizes, bucket, Item{operands[i], static_cast<std::uint8_t>(i)});
            write_i64(staged, at, -2);
            continue;
        }
        int bucket = 0;
        while (bucket < bucket_count && sizes[bucket] == 0) ++bucket;
        if (bucket == bucket_count) { write_i64(staged, at, -1); continue; }
        const auto item = heaps[bucket][0];
        write_i64(staged, at, (static_cast<std::int64_t>(item.insertion) << 8) | item.key);
        if (opcodes[i] == 2) pop(heaps, sizes, bucket);
    }
    const auto required = static_cast<std::size_t>(q + 1) * 8;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t i = 0; i < required; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(required);
}

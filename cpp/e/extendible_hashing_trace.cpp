#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int KeyCount = 256, MaxOps = 40, MaxWords = 82, MaxDepth = 8;
struct Table {
    std::array<std::uint8_t, KeyCount> directory{};
    std::array<std::array<std::uint8_t, 2>, KeyCount> keys{};
    std::array<std::uint8_t, KeyCount> counts{}, depths{}, active{};
    int global_depth = 1, high_depth = 1, bucket_count = 2, live = 0;
    Table() { directory[0] = 0; directory[1] = 1; active[0] = active[1] = 1; depths[0] = depths[1] = 1; }
    int bucket_for(int key) const { return directory[key & ((1 << global_depth) - 1)]; }
    int find(int bucket, int key) const {
        for (int i = 0; i < counts[bucket]; ++i) if (keys[bucket][i] == key) return i;
        return -1;
    }
    bool split(int bucket) {
        const int depth = depths[bucket];
        if (depth >= MaxDepth) return false;
        if (depth == global_depth) {
            const int old_size = 1 << global_depth;
            for (int i = 0; i < old_size; ++i) directory[i + old_size] = directory[i];
            ++global_depth; if (global_depth > high_depth) high_depth = global_depth;
        }
        int fresh = 0; while (fresh < KeyCount && active[fresh]) ++fresh;
        if (fresh == KeyCount) return false;
        active[fresh] = 1; depths[bucket] = depths[fresh] = static_cast<std::uint8_t>(depth + 1);
        const int old_count = counts[bucket];
        const auto old_keys = keys[bucket];
        counts[bucket] = counts[fresh] = 0; keys[bucket] = {}; keys[fresh] = {};
        const int bit = 1 << depth, size = 1 << global_depth;
        for (int i = 0; i < size; ++i) if (directory[i] == bucket && (i & bit)) directory[i] = static_cast<std::uint8_t>(fresh);
        for (int i = 0; i < old_count; ++i) {
            const int target = (old_keys[i] & bit) ? fresh : bucket;
            keys[target][counts[target]++] = old_keys[i];
        }
        ++bucket_count; return true;
    }
    void coalesce(int bucket) {
        while (depths[bucket] > 1) {
            const int depth = depths[bucket], size = 1 << global_depth;
            int representative = -1;
            for (int i = 0; i < size; ++i) if (directory[i] == bucket) { representative = i; break; }
            if (representative < 0) break;
            const int prefix = representative & ((1 << depth) - 1);
            const int buddy_prefix = prefix ^ (1 << (depth - 1));
            const int buddy = directory[buddy_prefix];
            if (buddy == bucket || !active[buddy] || depths[buddy] != depth || counts[bucket] + counts[buddy] > 2) break;
            const int survivor = buddy_prefix < prefix ? buddy : bucket;
            const int removed = survivor == bucket ? buddy : bucket;
            for (int i = 0; i < counts[removed]; ++i) keys[survivor][counts[survivor] + i] = keys[removed][i];
            counts[survivor] = static_cast<std::uint8_t>(counts[survivor] + counts[removed]);
            counts[removed] = 0; keys[removed] = {}; depths[survivor] = static_cast<std::uint8_t>(depth - 1); active[removed] = 0;
            for (int i = 0; i < size; ++i) if (directory[i] == removed) directory[i] = static_cast<std::uint8_t>(survivor);
            --bucket_count; bucket = survivor;
        }
        while (global_depth > 1) {
            const int half = 1 << (global_depth - 1); bool mirrors = true;
            for (int i = 0; i < half; ++i) if (directory[i] != directory[i + half]) { mirrors = false; break; }
            if (!mirrors) break; --global_depth;
        }
    }
};
}

extern "C" std::int64_t extendible_hashing_trace(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 1 || length > MaxWords) return -1;
    const auto q64 = input[0];
    if (q64 < 0 || q64 > MaxOps || length != 1 + 2 * static_cast<std::size_t>(q64)) return -1;
    const int q = static_cast<int>(q64);
    for (int i = 0; i < q; ++i) if (input[1 + 2 * i] < 0 || input[1 + 2 * i] > 2 || input[2 + 2 * i] < 0 || input[2 + 2 * i] > 255) return -1;
    Table table; std::uint64_t successes = 0;
    for (int i = 0; i < q; ++i) {
        const int op = static_cast<int>(input[1 + 2 * i]), key = static_cast<int>(input[2 + 2 * i]);
        int bucket = table.bucket_for(key), slot = table.find(bucket, key), success = 0;
        if (op == 0 && slot < 0) {
            while (table.counts[bucket] == 2) { if (!table.split(bucket)) break; bucket = table.bucket_for(key); }
            if (table.counts[bucket] < 2) { table.keys[bucket][table.counts[bucket]++] = static_cast<std::uint8_t>(key); ++table.live; success = 1; }
        } else if (op == 1 && slot >= 0) {
            --table.counts[bucket]; table.keys[bucket][slot] = table.keys[bucket][table.counts[bucket]]; --table.live; success = 1; table.coalesce(bucket);
        } else if (op == 2) success = slot >= 0;
        successes = (successes << 1) | static_cast<std::uint64_t>(success);
    }
    return static_cast<std::int64_t>(successes | (static_cast<std::uint64_t>(table.bucket_count) << 40) |
        (static_cast<std::uint64_t>(table.global_depth) << 49) | (static_cast<std::uint64_t>(table.high_depth) << 53) |
        (static_cast<std::uint64_t>(table.live) << 57));
}

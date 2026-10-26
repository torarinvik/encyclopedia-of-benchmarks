#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 12, W = 32, INPUT = 25, OUTPUT = 104;
void put(std::uint8_t *out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (int i = 0; i < 8; ++i) { out[at + i] = static_cast<std::uint8_t>(bits); bits >>= 8; }
}
}

extern "C" std::int64_t universal_sequencing_doubling(const std::int64_t *v, std::size_t length,
    std::uint8_t *out, std::size_t capacity) {
    if (!v || length < 3 || length > INPUT || v[0] < 1 || v[0] > N || length != 1 + 2 * static_cast<std::size_t>(v[0])) return -1;
    const int n = static_cast<int>(v[0]);
    std::int64_t p[N]{}; int w[N]{}; int total = 0;
    for (int j = 0; j < n; ++j) {
        if (v[1 + 2 * j] < 1 || v[1 + 2 * j] > 255 || v[2 + 2 * j] < 1 || v[2 + 2 * j] > W) return -1;
        p[j] = v[1 + 2 * j]; w[j] = static_cast<int>(v[2 + 2 * j]); total += w[j];
    }
    if (total > W || (total & (total - 1)) != 0) return -1;
    std::uint16_t sets[6]{}; int levels = 0;
    for (int bound = 1; bound <= total; bound *= 2, ++levels) {
        std::int64_t best[W + 1]{}; std::uint16_t masks[W + 1]{}; bool reach[W + 1]{}; reach[0] = true;
        for (int j = 0; j < n; ++j) for (int used = bound; used >= w[j]; --used) {
            if (!reach[used - w[j]]) continue;
            const auto candidate = best[used - w[j]] + p[j];
            const auto mask = static_cast<std::uint16_t>(masks[used - w[j]] | (1u << j));
            if (!reach[used] || candidate > best[used] || (candidate == best[used] && mask < masks[used])) {
                reach[used] = true; best[used] = candidate; masks[used] = mask;
            }
        }
        std::int64_t maximum = -1; std::uint16_t selected = 0;
        for (int used = 0; used <= bound; ++used) if (reach[used] &&
            (best[used] > maximum || (best[used] == maximum && masks[used] < selected))) {
            maximum = best[used]; selected = masks[used];
        }
        sets[levels] = selected;
    }
    int rank[N];
    for (int j = 0; j < n; ++j) {
        rank[j] = -1;
        for (int level = 0; level < levels; ++level) if ((sets[level] & (1u << j)) != 0) { rank[j] = level; break; }
        if (rank[j] < 0) return -1;
    }
    std::int64_t words[N + 1]{}; words[0] = n; int count = 1;
    for (int level = levels - 1; level >= 0; --level) for (int j = 0; j < n; ++j) if (rank[j] == level) words[count++] = j;
    const std::size_t bytes = 8 * static_cast<std::size_t>(count);
    std::uint8_t staged[OUTPUT]{}; for (int i = 0; i < count; ++i) put(staged, 8 * static_cast<std::size_t>(i), words[i]);
    if (!out || capacity < bytes) return -2;
    for (std::size_t i = 0; i < bytes; ++i) out[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}

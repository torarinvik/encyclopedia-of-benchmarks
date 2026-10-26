// Clean-room bounded GARDENIA Forward-Backward-Trim SCC profile.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16, MaxM = 64, MaxInput = 130, MaxTasks = 34;
using Mask = std::uint32_t;
Mask reach(Mask active, int pivot, const std::array<std::uint8_t, MaxN * MaxN>& adj,
           bool reverse, int n) {
    Mask seen = Mask{1} << pivot;
    for (;;) {
        Mask expanded = seen;
        for (int u = 0; u < n; ++u) {
            if (!(seen & (Mask{1} << u)) || !(active & (Mask{1} << u))) continue;
            for (int v = 0; v < n; ++v) {
                const bool edge = reverse ? adj[static_cast<std::size_t>(v) * MaxN + u]
                                          : adj[static_cast<std::size_t>(u) * MaxN + v];
                if ((active & (Mask{1} << v)) && edge) expanded |= Mask{1} << v;
            }
        }
        if (expanded == seen) return seen;
        seen = expanded;
    }
}
void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t gardenia_fb_trim_scc(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MaxM) ||
        length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const int n = static_cast<int>(n64), m = static_cast<int>(m64);
    std::array<std::uint8_t, MaxN * MaxN> adj{};
    for (int e = 0; e < m; ++e) {
        const auto u64 = input[2 + 2 * static_cast<std::size_t>(e)];
        const auto v64 = input[3 + 2 * static_cast<std::size_t>(e)];
        if (u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adj[u * MaxN + v]) return -1;
        adj[u * MaxN + v] = 1;
    }
    const auto outputBytes = 8 * static_cast<std::size_t>(n);
    if (!output || capacity < outputBytes) return -2;
    std::array<std::int64_t, MaxN> labels{};
    std::array<std::uint32_t, MaxTasks> tasks{};
    std::size_t taskCount = 1;
    tasks[0] = (std::uint32_t{1} << n) - 1;
    while (taskCount > 0) {
        auto active = tasks[--taskCount];
        while (active) {
            std::uint32_t trimmed = 0;
            for (int u = 0; u < n; ++u) {
                const auto ub = std::uint32_t{1} << u;
                if (!(active & ub)) continue;
                bool in = false, out = false;
                for (int v = 0; v < n; ++v) {
                    if (!(active & (std::uint32_t{1} << v))) continue;
                    out = out || adj[static_cast<std::size_t>(u) * MaxN + v];
                    in = in || adj[static_cast<std::size_t>(v) * MaxN + u];
                }
                if (!in || !out) trimmed |= ub;
            }
            if (!trimmed) break;
            for (int u = 0; u < n; ++u)
                if (trimmed & (std::uint32_t{1} << u)) labels[u] = u;
            active &= ~trimmed;
        }
        if (!active) continue;
        int pivot = 0;
        while (!(active & (std::uint32_t{1} << pivot))) ++pivot;
        const auto forward = reach(active, pivot, adj, false, n);
        const auto backward = reach(active, pivot, adj, true, n);
        const auto component = forward & backward;
        int representative = 0;
        while (!(component & (std::uint32_t{1} << representative))) ++representative;
        for (int u = 0; u < n; ++u)
            if (component & (std::uint32_t{1} << u)) labels[u] = representative;
        const std::array<std::uint32_t, 3> children{
            active & ~(forward | backward), forward & ~backward, backward & ~forward};
        for (auto child : children) if (child) {
            if (taskCount >= MaxTasks) return -1;
            tasks[taskCount++] = child;
        }
    }
    for (int u = 0; u < n; ++u) storeI64LE(output, 8 * static_cast<std::size_t>(u), labels[u]);
    return static_cast<std::int64_t>(outputBytes);
}

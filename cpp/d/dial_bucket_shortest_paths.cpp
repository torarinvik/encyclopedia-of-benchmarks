#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16, MaxM = 64, MaxDistance = 120, Buckets = 9, MaxRecords = 65;
void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t dial_bucket_shortest_paths(const std::int64_t* input, std::size_t length,
                                                    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 3 || length > 196) return -1;
    const auto n64 = input[0], m64 = input[1], source64 = input[2];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MaxM) || source64 < 0 || source64 >= n64 ||
        length != 3 + 3 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    const auto source = static_cast<std::size_t>(source64);
    std::array<std::size_t, MaxM> to{}, next{};
    std::array<std::int64_t, MaxM> weight{};
    std::array<std::size_t, MaxN> head{};
    head.fill(MaxM);
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u = input[3 + 3 * edge], v = input[4 + 3 * edge], w = input[5 + 3 * edge];
        if (u < 0 || u >= n64 || v < 0 || v >= n64 || w < 0 || w > 8) return -1;
        const auto from = static_cast<std::size_t>(u);
        to[edge] = static_cast<std::size_t>(v);
        weight[edge] = w;
        next[edge] = head[from];
        head[from] = edge;
    }
    const std::size_t needed = 8 * n;
    if (!output || capacity < needed) return -2;

    std::array<std::int64_t, MaxN> distance{};
    std::array<bool, MaxN> settled{};
    distance.fill(static_cast<std::int64_t>(MaxDistance + 1));
    distance[source] = 0;
    std::array<std::size_t, Buckets> bucket_head{}, bucket_tail{};
    bucket_head.fill(MaxRecords);
    bucket_tail.fill(MaxRecords);
    std::array<std::size_t, MaxRecords> record_vertex{}, record_next{};
    std::array<std::int64_t, MaxRecords> record_distance{};
    std::size_t used = 1;
    record_vertex[0] = source;
    record_distance[0] = 0;
    record_next[0] = MaxRecords;
    bucket_head[0] = bucket_tail[0] = 0;
    for (std::size_t current = 0; current <= MaxDistance; ++current) {
        const auto bucket = current % Buckets;
        while (bucket_head[bucket] != MaxRecords) {
            const auto record = bucket_head[bucket];
            bucket_head[bucket] = record_next[record];
            if (bucket_head[bucket] == MaxRecords) bucket_tail[bucket] = MaxRecords;
            const auto u = record_vertex[record];
            if (record_distance[record] != static_cast<std::int64_t>(current) ||
                settled[u] || distance[u] != static_cast<std::int64_t>(current)) continue;
            settled[u] = true;
            for (auto edge = head[u]; edge != MaxM; edge = next[edge]) {
                const auto v = to[edge];
                const auto candidate = static_cast<std::int64_t>(current) + weight[edge];
                if (!settled[v] && candidate < distance[v]) {
                    if (used >= MaxRecords) return -1;
                    distance[v] = candidate;
                    const auto destination = static_cast<std::size_t>(candidate) % Buckets;
                    record_vertex[used] = v;
                    record_distance[used] = candidate;
                    record_next[used] = MaxRecords;
                    if (bucket_tail[destination] == MaxRecords) bucket_head[destination] = used;
                    else record_next[bucket_tail[destination]] = used;
                    bucket_tail[destination] = used++;
                }
            }
        }
    }
    std::array<std::uint8_t, 128> staged{};
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        put_i64_le(staged.data(), 8 * vertex, distance[vertex] > static_cast<std::int64_t>(MaxDistance) ? -1 : distance[vertex]);
    for (std::size_t byte = 0; byte < needed; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(needed);
}


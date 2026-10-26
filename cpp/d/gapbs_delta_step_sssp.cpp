// Clean-room bounded GAPBS delta-stepping profile; see package LICENSE.txt.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16, MaxM = 64, MaxInput = 4 + 3 * MaxM;
constexpr std::size_t MaxDistance = 480, MaxBuckets = MaxDistance + 1, MaxEvents = 8192;
constexpr std::int64_t InfDistance = INT64_C(1073741823);

bool appendEvent(std::size_t bucket, std::size_t vertex,
                 std::array<int, MaxBuckets>& heads, std::array<int, MaxBuckets>& tails,
                 std::array<int, MaxEvents>& eventVertex, std::array<int, MaxEvents>& eventNext,
                 std::size_t& used) noexcept {
    if (used >= MaxEvents || bucket >= MaxBuckets) return false;
    const int event = static_cast<int>(used++);
    eventVertex[static_cast<std::size_t>(event)] = static_cast<int>(vertex);
    eventNext[static_cast<std::size_t>(event)] = -1;
    if (heads[bucket] < 0) heads[bucket] = event;
    else eventNext[static_cast<std::size_t>(tails[bucket])] = event;
    tails[bucket] = event;
    return true;
}

void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
} // namespace

extern "C" std::int64_t gapbs_delta_step_sssp(const std::int64_t* input, std::size_t length,
                                               std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 4 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1], source64 = input[2], delta64 = input[3];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 || m64 > static_cast<std::int64_t>(MaxM) ||
        source64 < 0 || source64 >= n64 || delta64 < 1 || delta64 > 16 ||
        length != 4 + 3 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    const auto delta = static_cast<std::int64_t>(delta64);
    std::array<int, MaxM> edgeFrom{}, edgeTo{}, edgeWeight{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto from = input[4 + 3 * edge], to = input[5 + 3 * edge], weight = input[6 + 3 * edge];
        if (from < 0 || from >= n64 || to < 0 || to >= n64 || weight < 0 || weight > 32) return -1;
        edgeFrom[edge] = static_cast<int>(from);
        edgeTo[edge] = static_cast<int>(to);
        edgeWeight[edge] = static_cast<int>(weight);
    }
    const auto outputBytes = 8 * n;
    if (!output || capacity < outputBytes) return -2;

    std::array<std::int64_t, MaxN> distance{};
    distance.fill(InfDistance);
    distance[static_cast<std::size_t>(source64)] = 0;
    std::array<int, MaxBuckets> heads{}, tails{};
    heads.fill(-1);
    tails.fill(-1);
    std::array<int, MaxEvents> eventVertex{}, eventNext{};
    std::size_t used = 0;
    if (!appendEvent(0, static_cast<std::size_t>(source64), heads, tails, eventVertex, eventNext, used)) return -1;

    for (std::size_t bucket = 0; bucket < MaxBuckets; ++bucket) {
        while (heads[bucket] >= 0) {
            const auto event = static_cast<std::size_t>(heads[bucket]);
            heads[bucket] = eventNext[event];
            if (heads[bucket] < 0) tails[bucket] = -1;
            const auto u = static_cast<std::size_t>(eventVertex[event]);
            if (distance[u] < delta * static_cast<std::int64_t>(bucket)) continue;
            for (std::size_t edge = 0; edge < m; ++edge) {
                if (edgeFrom[edge] != static_cast<int>(u)) continue;
                const auto v = static_cast<std::size_t>(edgeTo[edge]);
                const auto candidate = distance[u] + edgeWeight[edge];
                if (candidate < distance[v]) {
                    distance[v] = candidate;
                    const auto destination = static_cast<std::size_t>(candidate / delta);
                    if (!appendEvent(destination, v, heads, tails, eventVertex, eventNext, used)) return -1;
                }
            }
        }
    }
    for (std::size_t vertex = 0; vertex < n; ++vertex) storeI64LE(output, 8 * vertex, distance[vertex]);
    return static_cast<std::int64_t>(outputBytes);
}

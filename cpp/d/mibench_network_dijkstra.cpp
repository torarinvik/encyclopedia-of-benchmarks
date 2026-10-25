#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxNodes = 6;
constexpr int kMaxQueueItems = 1024;
constexpr std::int64_t kNone = 9999;
struct QueueItem { int node; std::int64_t distance; int previous; };
}

extern "C" std::int64_t mibench_network_dijkstra(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 3) return -1;
    const std::int64_t node_value = input[0];
    if (node_value < 1 || node_value > kMaxNodes) return -1;
    const std::size_t nodes = static_cast<std::size_t>(node_value);
    if (length != 2 + nodes * nodes) return -1;
    const std::int64_t source_value = input[1];
    if (source_value < 0 || static_cast<std::uint64_t>(source_value) >= nodes) return -1;
    for (std::size_t i = 0; i < nodes * nodes; ++i) {
        const std::int64_t cost = input[2 + i];
        if (cost != kNone && (cost < 0 || cost > 31)) return -1;
    }

    std::int64_t distance[kMaxNodes];
    bool reachable[kMaxNodes]{};
    QueueItem queue[kMaxQueueItems];
    for (std::size_t i = 0; i < nodes; ++i) distance[i] = kNone;
    const int source = static_cast<int>(source_value);
    distance[source] = 0;
    reachable[source] = true;
    std::size_t head = 0, tail = 0;
    queue[tail++] = {source, 0, static_cast<int>(kNone)};
    while (head < tail) {
        const QueueItem item = queue[head++];
        for (std::size_t destination = 0; destination < nodes; ++destination) {
            const std::int64_t cost = input[2 + static_cast<std::size_t>(item.node) * nodes + destination];
            if (cost == kNone) continue;
            const std::int64_t candidate = item.distance + cost;
            if (!reachable[destination] || distance[destination] > candidate) {
                distance[destination] = candidate;
                reachable[destination] = true;
                if (tail >= kMaxQueueItems) return -2;
                queue[tail++] = {static_cast<int>(destination), candidate, item.node};
            }
        }
    }
    std::int64_t checksum = 0;
    std::uint64_t mask = 0;
    for (std::size_t node = 0; node < nodes; ++node) {
        if (reachable[node]) {
            checksum += static_cast<std::int64_t>(node + 1) * distance[node];
            mask |= std::uint64_t{1} << node;
        }
    }
    return checksum + static_cast<std::int64_t>(mask);
}

#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxVertices = 8;
constexpr std::size_t kMaxParseableInput = 117;
constexpr std::size_t kOutputBytes = 16;
using Adjacency = std::array<std::uint16_t, kMaxVertices>;

int shortestPath(const Adjacency& adjacency, int n, int source, int target,
                 std::array<int, kMaxVertices>& path) {
    std::array<int, kMaxVertices> distance{};
    std::array<int, kMaxVertices> predecessor{};
    std::array<int, kMaxVertices> queue{};
    distance.fill(-1);
    predecessor.fill(-1);
    int head = 0, tail = 0;
    queue[tail++] = source;
    distance[source] = 0;
    while (head < tail) {
        const int vertex = queue[head++];
        for (int successor = 0; successor < n; ++successor) {
            const auto bit = static_cast<std::uint16_t>(1u << successor);
            if ((adjacency[vertex] & bit) != 0 && distance[successor] == -1) {
                distance[successor] = distance[vertex] + 1;
                predecessor[successor] = vertex;
                queue[tail++] = successor;
            }
        }
    }
    if (distance[target] == -1) return 0;
    std::array<int, kMaxVertices> reversed{};
    int count = 0;
    for (int vertex = target; vertex != -1; vertex = predecessor[vertex]) {
        reversed[count++] = vertex;
        if (vertex == source) break;
    }
    if (reversed[count - 1] != source) return 0;
    for (int index = 0; index < count; ++index) path[index] = reversed[count - index - 1];
    return count;
}

std::int64_t gcd(std::int64_t left, std::int64_t right) {
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

void writeI64(std::uint8_t* output, int word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (int byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t network_erosion_strength_of_connection(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 4 || length > kMaxParseableInput) return -1;
    const auto vertexRaw = input[0];
    const auto edgeRaw = input[1];
    const auto sourceRaw = input[2];
    const auto targetRaw = input[3];
    if (vertexRaw < 2 || vertexRaw > 8 || edgeRaw < 0 ||
        edgeRaw > vertexRaw * (vertexRaw - 1) || sourceRaw < 0 || sourceRaw >= vertexRaw ||
        targetRaw < 0 || targetRaw >= vertexRaw || sourceRaw == targetRaw) return -1;
    const int n = static_cast<int>(vertexRaw);
    const int edgeCount = static_cast<int>(edgeRaw);
    const int source = static_cast<int>(sourceRaw);
    const int target = static_cast<int>(targetRaw);
    if (length != static_cast<std::size_t>(4 + 2 * edgeCount)) return -1;

    Adjacency adjacency{};
    std::size_t cursor = 4;
    for (int edge = 0; edge < edgeCount; ++edge) {
        const auto fromRaw = input[cursor++];
        const auto toRaw = input[cursor++];
        if (fromRaw < 0 || fromRaw >= n || toRaw < 0 || toRaw >= n || fromRaw == toRaw)
            return -1;
        const int from = static_cast<int>(fromRaw);
        const int to = static_cast<int>(toRaw);
        const auto bit = static_cast<std::uint16_t>(1u << to);
        if ((adjacency[from] & bit) != 0) return -1;
        adjacency[from] |= bit;
    }

    std::array<int, kMaxVertices> distances{};
    distances.fill(-1);
    std::array<int, kMaxVertices> path{};
    const int firstCount = shortestPath(adjacency, n, source, target, path);
    if (firstCount != 0) {
        const int initialLength = firstCount - 1;
        distances[source] = initialLength;
        distances[target] = initialLength;
        for (;;) {
            const int pathCount = shortestPath(adjacency, n, source, target, path);
            if (pathCount == 0) break;
            const int pathLength = pathCount - 1;
            if (pathLength == 1) {
                adjacency[source] &= static_cast<std::uint16_t>(~(1u << target));
                continue;
            }
            for (int index = 0; index < pathCount; ++index) {
                const int vertex = path[index];
                if (distances[vertex] == -1) distances[vertex] = pathLength;
            }
            for (int index = 1; index + 1 < pathCount; ++index) {
                const int vertex = path[index];
                const auto bit = static_cast<std::uint16_t>(1u << vertex);
                adjacency[vertex] = 0;
                for (int other = 0; other < n; ++other)
                    adjacency[other] &= static_cast<std::uint16_t>(~bit);
            }
        }
    }

    std::int64_t reciprocalSumScaled = 0;
    for (int vertex = 0; vertex < n; ++vertex)
        if (distances[vertex] >= 1) reciprocalSumScaled += 420 / distances[vertex];
    std::int64_t numerator = 2 * reciprocalSumScaled;
    std::int64_t denominator = 420 * (n + 2);
    if (numerator == 0) {
        denominator = 1;
    } else {
        const auto divisor = gcd(numerator, denominator);
        numerator /= divisor;
        denominator /= divisor;
    }
    if (output == nullptr || capacity < kOutputBytes) return -2;
    writeI64(output, 0, numerator);
    writeI64(output, 1, denominator);
    return static_cast<std::int64_t>(kOutputBytes);
}

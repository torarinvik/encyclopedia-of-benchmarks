#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 12, T = 20, C = 60, INPUT = 64;

void put_word(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (unsigned byte = 0; byte < 8; ++byte)
        out[offset + byte] = static_cast<std::uint8_t>((bits >> (8u * byte)) & 255u);
}

int vertex_at(const std::int64_t *faces, int corner) {
    return static_cast<int>(faces[3 * (corner / 3) + corner % 3]);
}
int next(int corner) { return 3 * (corner / 3) + (corner % 3 + 1) % 3; }
int previous(int corner) { return 3 * (corner / 3) + (corner % 3 + 2) % 3; }

bool run(int n, int t, int seed, const std::int64_t *faces,
         std::array<std::int64_t, C> &trace, int &count,
         std::uint64_t &vertex_mask, std::uint64_t &triangle_mask) {
    std::array<int, C> opposite{};
    std::array<std::array<std::array<bool, N>, N>, N> link{};
    std::array<bool, N> used{};
    std::array<std::array<std::uint8_t, N>, N> edge_count{};
    std::array<std::array<std::int32_t, N>, N> edge_first{};
    std::array<std::array<std::int32_t, N>, N> edge_second{};
    for (int corner = 0; corner < 3 * t; ++corner) opposite[corner] = -1;
    for (int a = 0; a < N; ++a) for (int b = 0; b < N; ++b)
        edge_first[a][b] = edge_second[a][b] = -1;
    for (int ti = 0; ti < t; ++ti) {
        const int a = static_cast<int>(faces[3 * ti]);
        const int b = static_cast<int>(faces[3 * ti + 1]);
        const int c = static_cast<int>(faces[3 * ti + 2]);
        used[a] = used[b] = used[c] = true;
        link[a][b][c] = link[a][c][b] = true;
        link[b][c][a] = link[b][a][c] = true;
        link[c][a][b] = link[c][b][a] = true;
        for (int j = 0; j < 3; ++j) {
            const int first = static_cast<int>(faces[3 * ti + (j + 1) % 3]);
            const int second = static_cast<int>(faces[3 * ti + (j + 2) % 3]);
            const int low = first < second ? first : second;
            const int high = first < second ? second : first;
            const std::uint8_t used_edges = edge_count[low][high];
            if (used_edges == 0) edge_first[low][high] = 3 * ti + j;
            else if (used_edges == 1) edge_second[low][high] = 3 * ti + j;
            else return false;
            edge_count[low][high] = static_cast<std::uint8_t>(used_edges + 1);
        }
    }
    for (int v = 0; v < n; ++v) if (!used[v]) return false;

    for (int low = 0; low < n; ++low) for (int high = low + 1; high < n; ++high) {
        if (edge_count[low][high] == 0) continue;
        if (edge_count[low][high] != 2) return false;
        const int a = edge_first[low][high], b = edge_second[low][high];
        const int at = a / 3, aj = a % 3, bt = b / 3, bj = b % 3;
        const int a0 = static_cast<int>(faces[3 * at + (aj + 1) % 3]);
        const int a1 = static_cast<int>(faces[3 * at + (aj + 2) % 3]);
        const int b0 = static_cast<int>(faces[3 * bt + (bj + 1) % 3]);
        const int b1 = static_cast<int>(faces[3 * bt + (bj + 2) % 3]);
        if (a0 != b1 || a1 != b0) return false;
        opposite[a] = b;
        opposite[b] = a;
    }

    for (int v = 0; v < n; ++v) {
        int start = -1;
        for (int w = 0; w < n; ++w) {
            int degree = 0;
            for (int x = 0; x < n; ++x) degree += link[v][w][x] ? 1 : 0;
            if (degree && start < 0) start = w;
            if (degree && degree != 2) return false;
        }
        if (start < 0) return false;
        std::array<bool, N> seen{};
        std::array<int, N> queue{};
        int head = 0, tail = 0;
        seen[start] = true; queue[tail++] = start;
        while (head < tail) {
            const int w = queue[head++];
            for (int x = 0; x < n; ++x)
                if (link[v][w][x] && !seen[x]) { seen[x] = true; queue[tail++] = x; }
        }
        for (int w = 0; w < n; ++w) {
            bool has_edge = false;
            for (int x = 0; x < n; ++x) has_edge |= link[v][w][x];
            if (has_edge && !seen[w]) return false;
        }
    }

    std::array<bool, T> reached{};
    std::array<int, T> queue{};
    int head = 0, tail = 0;
    reached[0] = true; queue[tail++] = 0;
    while (head < tail) {
        const int ti = queue[head++];
        for (int j = 0; j < 3; ++j) {
            const int other = opposite[3 * ti + j] / 3;
            if (!reached[other]) { reached[other] = true; queue[tail++] = other; }
        }
    }
    for (int ti = 0; ti < t; ++ti) if (!reached[ti]) return false;

    std::array<bool, C> seen_corners{};
    vertex_mask = triangle_mask = 0;
    count = 0;
    vertex_mask |= UINT64_C(1) << vertex_at(faces, next(seed));
    vertex_mask |= UINT64_C(1) << vertex_at(faces, previous(seed));
    const int stop = opposite[seed];
    int corner = seed;
    while (corner != stop) {
        if (corner < 0 || corner >= 3 * t || seen_corners[corner] || count >= 3 * t) return false;
        seen_corners[corner] = true;
        trace[count++] = corner;
        const int ti = corner / 3, vertex = vertex_at(faces, corner);
        if (((vertex_mask >> vertex) & 1u) == 0) {
            vertex_mask |= UINT64_C(1) << vertex;
            triangle_mask |= UINT64_C(1) << ti;
        } else if (((triangle_mask >> ti) & 1u) == 0) {
            corner = opposite[corner];
        }
        corner = opposite[previous(corner)];
    }
    return true;
}
} // namespace

extern "C" std::int64_t ring_expander_closed_triangle_mesh(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 15 || length > INPUT) return -1;
    const std::int64_t n64 = input[0], t64 = input[1], seed64 = input[2];
    if (n64 < 4 || n64 > N || t64 < 4 || t64 > T ||
        length != 3u + 3u * static_cast<std::size_t>(t64) || seed64 < 0 || seed64 >= 3 * t64)
        return -1;
    const int n = static_cast<int>(n64), t = static_cast<int>(t64), seed = static_cast<int>(seed64);
    const std::int64_t *faces = input + 3;
    for (int i = 0; i < 3 * t; ++i) if (faces[i] < 0 || faces[i] >= n64) return -1;
    for (int ti = 0; ti < t; ++ti)
        if (faces[3 * ti] == faces[3 * ti + 1] || faces[3 * ti + 1] == faces[3 * ti + 2] ||
            faces[3 * ti + 2] == faces[3 * ti]) return -1;
    std::array<std::int64_t, C> trace{};
    int count = 0;
    std::uint64_t vertices = 0, triangles = 0;
    if (!run(n, t, seed, faces, trace, count, vertices, triangles)) return -1;
    const std::size_t words = 1u + static_cast<std::size_t>(count) + 2u;
    const std::size_t bytes = 8u * words;
    if (output == nullptr || capacity < bytes) return -2;
    put_word(output, 0, count);
    for (int i = 0; i < count; ++i) put_word(output, 8u * (i + 1u), trace[i]);
    put_word(output, 8u * (count + 1u), static_cast<std::int64_t>(vertices));
    put_word(output, 8u * (count + 2u), static_cast<std::int64_t>(triangles));
    return static_cast<std::int64_t>(bytes);
}

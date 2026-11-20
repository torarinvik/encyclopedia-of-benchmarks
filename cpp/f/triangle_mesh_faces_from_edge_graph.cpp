#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kVertices = 8;
constexpr int kEdges = 28;
constexpr int kTriangles = 56;
constexpr std::size_t kInputWords = 59;
constexpr std::size_t kOutputWords = 170;

struct Triangle { int a, b, c, e0, e1, e2; bool active; };

bool has_edge(const Triangle &triangle, int edge) {
    return triangle.e0 == edge || triangle.e1 == edge || triangle.e2 == edge;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

void select_triangle(std::size_t chosen, std::array<Triangle, kTriangles> &triangles,
        std::size_t triangle_count, std::array<int, kEdges> &incidence,
        std::array<int, kEdges> &used, std::array<std::int64_t, kOutputWords> &staged,
        std::size_t &face_count) {
    auto &triangle = triangles[chosen];
    triangle.active = false;
    staged[2 + 3 * face_count] = triangle.a;
    staged[3 + 3 * face_count] = triangle.b;
    staged[4 + 3 * face_count] = triangle.c;
    ++face_count;

    const std::array<int, 3> edges{triangle.e0, triangle.e1, triangle.e2};
    std::array<int, 3> saturated{-1, -1, -1};
    std::size_t saturated_count = 0;
    for (int edge : edges) {
        --incidence[edge];
        ++used[edge];
        if (used[edge] == 2) saturated[saturated_count++] = edge;
    }
    for (std::size_t other = 0; other < triangle_count; ++other) {
        if (!triangles[other].active) continue;
        bool remove = false;
        for (std::size_t j = 0; j < saturated_count; ++j)
            remove = remove || has_edge(triangles[other], saturated[j]);
        if (remove) {
            triangles[other].active = false;
            --incidence[triangles[other].e0];
            --incidence[triangles[other].e1];
            --incidence[triangles[other].e2];
        }
    }
}
} // namespace

extern "C" std::int64_t triangle_mesh_faces_from_edge_graph(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kInputWords) return -1;
    const auto vertex_word = input[0], edge_word = input[1];
    if (vertex_word < 3 || vertex_word > kVertices || edge_word < 0 || edge_word > kEdges) return -1;
    const int vertices = static_cast<int>(vertex_word), edge_count = static_cast<int>(edge_word);
    if (edge_count > vertices * (vertices - 1) / 2 || length != static_cast<std::size_t>(2 + 2 * edge_count)) return -1;

    std::array<std::array<int, kVertices>, kVertices> edge_index{};
    for (auto &row : edge_index) row.fill(-1);
    std::array<int, kVertices> vertex_degree{};
    for (int edge = 0; edge < edge_count; ++edge) {
        auto left_word = input[2 + 2 * edge], right_word = input[3 + 2 * edge];
        if (left_word < 0 || left_word >= vertices || right_word < 0 || right_word >= vertices || left_word == right_word) return -1;
        int left = static_cast<int>(left_word), right = static_cast<int>(right_word);
        if (left > right) { const int swap = left; left = right; right = swap; }
        if (edge_index[left][right] >= 0) return -1;
        edge_index[left][right] = edge_index[right][left] = edge;
        ++vertex_degree[left]; ++vertex_degree[right];
    }

    std::array<Triangle, kTriangles> triangles{};
    std::size_t triangle_count = 0;
    std::array<int, kEdges> incidence{};
    for (int a = 0; a < vertices; ++a) for (int b = a + 1; b < vertices; ++b)
        for (int c = b + 1; c < vertices; ++c) {
            const int e0 = edge_index[a][b], e1 = edge_index[a][c], e2 = edge_index[b][c];
            if (e0 >= 0 && e1 >= 0 && e2 >= 0) {
                triangles[triangle_count++] = Triangle{a, b, c, e0, e1, e2, true};
                ++incidence[e0]; ++incidence[e1]; ++incidence[e2];
            }
        }

    std::array<int, kEdges> used{};
    std::array<std::int64_t, kOutputWords> staged{};
    std::size_t face_count = 0;
    bool fallback_used = false;
    for (;;) {
        std::size_t chosen = triangle_count;
        for (std::size_t i = 0; i < triangle_count; ++i) {
            const auto &t = triangles[i];
            if (t.active && (vertex_degree[t.a] == 3 || vertex_degree[t.b] == 3 || vertex_degree[t.c] == 3)) { chosen = i; break; }
        }
        if (chosen < triangle_count) {
            select_triangle(chosen, triangles, triangle_count, incidence, used, staged, face_count);
            continue;
        }

        std::array<bool, kEdges> forced{};
        for (int edge = 0; edge < edge_count; ++edge)
            forced[edge] = incidence[edge] > 0 && incidence[edge] == 2 - used[edge];
        chosen = triangle_count;
        for (std::size_t i = 0; i < triangle_count; ++i) {
            const auto &t = triangles[i];
            if (t.active && (forced[t.e0] || forced[t.e1] || forced[t.e2])) { chosen = i; break; }
        }
        if (chosen < triangle_count) {
            select_triangle(chosen, triangles, triangle_count, incidence, used, staged, face_count);
            continue;
        }

        int best_score = 3 * kTriangles + 1;
        chosen = triangle_count;
        for (std::size_t i = 0; i < triangle_count; ++i) {
            const auto &t = triangles[i];
            if (!t.active) continue;
            const int score = incidence[t.e0] + incidence[t.e1] + incidence[t.e2];
            if (score < best_score) { best_score = score; chosen = i; }
        }
        if (chosen == triangle_count) break;
        fallback_used = true;
        select_triangle(chosen, triangles, triangle_count, incidence, used, staged, face_count);
    }

    bool complete = edge_count > 0;
    for (int edge = 0; edge < edge_count; ++edge) complete = complete && used[edge] == 2;
    staged[0] = (complete ? 0 : 2) + static_cast<int>(fallback_used);
    staged[1] = static_cast<std::int64_t>(face_count);
    const std::size_t output_bytes = (2 + 3 * face_count) * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t word = 0; word < 2 + 3 * face_count; ++word)
        store_i64_le(output, word * 8, staged[word]);
    return static_cast<std::int64_t>(output_bytes);
}

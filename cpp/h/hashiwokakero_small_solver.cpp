#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxIslands = 6;
constexpr std::size_t MaxEdgeSlots = 12;
constexpr std::size_t MaxParseableInputLength = 20;

struct Solver {
    std::size_t island_count = 0;
    std::size_t edge_count = 0;
    std::int64_t x[MaxIslands]{};
    std::int64_t y[MaxIslands]{};
    std::int64_t residual[MaxIslands]{};
    std::size_t remaining[MaxIslands]{};
    std::size_t edge_u[MaxEdgeSlots]{};
    std::size_t edge_v[MaxEdgeSlots]{};
    std::uint8_t multiplicity[MaxEdgeSlots]{};
    std::uint8_t solution[MaxEdgeSlots]{};
};

bool edges_cross(const Solver &solver, std::size_t first, std::size_t second) noexcept {
    const std::size_t a = solver.edge_u[first], b = solver.edge_v[first];
    const std::size_t c = solver.edge_u[second], d = solver.edge_v[second];
    const bool first_horizontal = solver.y[a] == solver.y[b];
    const bool second_horizontal = solver.y[c] == solver.y[d];
    if (first_horizontal == second_horizontal) return false;
    const std::size_t h0 = first_horizontal ? a : c;
    const std::size_t h1 = first_horizontal ? b : d;
    const std::size_t v0 = first_horizontal ? c : a;
    const std::size_t v1 = first_horizontal ? d : b;
    const std::int64_t hx = solver.x[v0], hy = solver.y[h0];
    const std::int64_t hmin = solver.x[h0] < solver.x[h1] ? solver.x[h0] : solver.x[h1];
    const std::int64_t hmax = solver.x[h0] > solver.x[h1] ? solver.x[h0] : solver.x[h1];
    const std::int64_t vmin = solver.y[v0] < solver.y[v1] ? solver.y[v0] : solver.y[v1];
    const std::int64_t vmax = solver.y[v0] > solver.y[v1] ? solver.y[v0] : solver.y[v1];
    return hmin < hx && hx < hmax && vmin < hy && hy < vmax;
}

bool possible_graph_connected(const Solver &solver, std::size_t assigned_through) noexcept {
    bool reached[MaxIslands]{};
    std::size_t stack[MaxIslands]{};
    std::size_t top = 0;
    reached[0] = true;
    stack[top++] = 0;
    while (top != 0) {
        const std::size_t island = stack[--top];
        for (std::size_t edge = 0; edge < solver.edge_count; ++edge) {
            bool usable = edge <= assigned_through && solver.multiplicity[edge] != 0;
            if (edge > assigned_through) {
                usable = true;
                for (std::size_t fixed = 0; fixed <= assigned_through; ++fixed) {
                    if (solver.multiplicity[fixed] != 0 && edges_cross(solver, fixed, edge)) {
                        usable = false;
                        break;
                    }
                }
            }
            if (!usable) continue;
            std::size_t neighbor = solver.island_count;
            if (solver.edge_u[edge] == island) neighbor = solver.edge_v[edge];
            else if (solver.edge_v[edge] == island) neighbor = solver.edge_u[edge];
            if (neighbor < solver.island_count && !reached[neighbor]) {
                reached[neighbor] = true;
                stack[top++] = neighbor;
            }
        }
    }
    for (std::size_t island = 0; island < solver.island_count; ++island)
        if (!reached[island]) return false;
    return true;
}

bool residuals_feasible(const Solver &solver) noexcept {
    for (std::size_t island = 0; island < solver.island_count; ++island)
        if (solver.residual[island] < 0 ||
            static_cast<std::uint64_t>(solver.residual[island]) > 2 * solver.remaining[island]) return false;
    return true;
}

bool search(Solver &solver, std::size_t depth) noexcept {
    if (depth == solver.edge_count) {
        for (std::size_t island = 0; island < solver.island_count; ++island)
            if (solver.residual[island] != 0) return false;
        if (!possible_graph_connected(solver, solver.edge_count - 1)) return false;
        for (std::size_t edge = 0; edge < solver.edge_count; ++edge)
            solver.solution[edge] = solver.multiplicity[edge];
        return true;
    }
    const std::size_t u = solver.edge_u[depth], v = solver.edge_v[depth];
    --solver.remaining[u];
    --solver.remaining[v];
    for (std::uint8_t amount = 0; amount <= 2; ++amount) {
        if (amount > solver.residual[u] || amount > solver.residual[v]) continue;
        bool conflict = false;
        if (amount != 0) {
            for (std::size_t prior = 0; prior < depth; ++prior) {
                if (solver.multiplicity[prior] != 0 && edges_cross(solver, prior, depth)) {
                    conflict = true;
                    break;
                }
            }
        }
        if (conflict) continue;
        solver.multiplicity[depth] = amount;
        solver.residual[u] -= amount;
        solver.residual[v] -= amount;
        if (residuals_feasible(solver) && possible_graph_connected(solver, depth) &&
            search(solver, depth + 1)) {
            solver.residual[u] += amount;
            solver.residual[v] += amount;
            ++solver.remaining[u];
            ++solver.remaining[v];
            return true;
        }
        solver.residual[u] += amount;
        solver.residual[v] += amount;
        solver.multiplicity[depth] = 0;
    }
    ++solver.remaining[u];
    ++solver.remaining[v];
    return false;
}
}

extern "C" std::int64_t hashiwokakero_small_solver(const std::int64_t *input,
                                                   std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > MaxParseableInputLength) return -1;
    if (input[0] < 2 || input[0] > static_cast<std::int64_t>(MaxIslands)) return -1;
    const std::size_t island_count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 3 * island_count) return -1;
    Solver solver;
    solver.island_count = island_count;
    for (std::size_t island = 0; island < island_count; ++island) {
        const std::int64_t x = input[1 + 3 * island];
        const std::int64_t y = input[2 + 3 * island];
        const std::int64_t demand = input[3 + 3 * island];
        if (x < 0 || x > 7 || y < 0 || y > 7 || demand < 1 || demand > 8) return -1;
        for (std::size_t prior = 0; prior < island; ++prior)
            if (solver.x[prior] == x && solver.y[prior] == y) return -1;
        solver.x[island] = x;
        solver.y[island] = y;
        solver.residual[island] = demand;
    }

    for (std::size_t first = 0; first < island_count; ++first) {
        for (std::size_t second = first + 1; second < island_count; ++second) {
            if (solver.x[first] != solver.x[second] && solver.y[first] != solver.y[second]) continue;
            bool blocked = false;
            for (std::size_t middle = 0; middle < island_count; ++middle) {
                if (middle == first || middle == second) continue;
                if (solver.y[first] == solver.y[second] && solver.y[middle] == solver.y[first] &&
                    ((solver.x[first] < solver.x[middle] && solver.x[middle] < solver.x[second]) ||
                     (solver.x[second] < solver.x[middle] && solver.x[middle] < solver.x[first]))) blocked = true;
                if (solver.x[first] == solver.x[second] && solver.x[middle] == solver.x[first] &&
                    ((solver.y[first] < solver.y[middle] && solver.y[middle] < solver.y[second]) ||
                     (solver.y[second] < solver.y[middle] && solver.y[middle] < solver.y[first]))) blocked = true;
            }
            if (!blocked) {
                if (solver.edge_count == MaxEdgeSlots) return -1;
                const std::size_t edge = solver.edge_count++;
                solver.edge_u[edge] = first;
                solver.edge_v[edge] = second;
                ++solver.remaining[first];
                ++solver.remaining[second];
            }
        }
    }
    if (!search(solver, 0)) return -2;
    std::uint64_t result = UINT64_C(1) << 32;
    for (std::size_t edge = 0; edge < solver.edge_count; ++edge)
        result |= static_cast<std::uint64_t>(solver.solution[edge]) << (2 * edge);
    return static_cast<std::int64_t>(result);
}

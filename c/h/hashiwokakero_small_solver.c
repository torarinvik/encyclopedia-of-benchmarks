#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_ISLANDS 6
#define MAX_EDGE_SLOTS 12
#define MAX_PARSEABLE_INPUT_LENGTH 20

typedef struct {
    size_t island_count;
    size_t edge_count;
    int64_t x[MAX_ISLANDS];
    int64_t y[MAX_ISLANDS];
    int64_t residual[MAX_ISLANDS];
    size_t remaining[MAX_ISLANDS];
    size_t edge_u[MAX_EDGE_SLOTS];
    size_t edge_v[MAX_EDGE_SLOTS];
    uint8_t multiplicity[MAX_EDGE_SLOTS];
    uint8_t solution[MAX_EDGE_SLOTS];
} Solver;

static bool edges_cross(const Solver *solver, size_t first, size_t second)
{
    const size_t a = solver->edge_u[first], b = solver->edge_v[first];
    const size_t c = solver->edge_u[second], d = solver->edge_v[second];
    const bool first_horizontal = solver->y[a] == solver->y[b];
    const bool second_horizontal = solver->y[c] == solver->y[d];
    if (first_horizontal == second_horizontal) return false;
    const size_t h0 = first_horizontal ? a : c;
    const size_t h1 = first_horizontal ? b : d;
    const size_t v0 = first_horizontal ? c : a;
    const size_t v1 = first_horizontal ? d : b;
    const int64_t hx = solver->x[v0], hy = solver->y[h0];
    const int64_t hmin = solver->x[h0] < solver->x[h1] ? solver->x[h0] : solver->x[h1];
    const int64_t hmax = solver->x[h0] > solver->x[h1] ? solver->x[h0] : solver->x[h1];
    const int64_t vmin = solver->y[v0] < solver->y[v1] ? solver->y[v0] : solver->y[v1];
    const int64_t vmax = solver->y[v0] > solver->y[v1] ? solver->y[v0] : solver->y[v1];
    return hmin < hx && hx < hmax && vmin < hy && hy < vmax;
}

static bool possible_graph_connected(const Solver *solver, size_t assigned_through)
{
    bool reached[MAX_ISLANDS] = {false};
    size_t stack[MAX_ISLANDS] = {0};
    size_t top = 0;
    reached[0] = true;
    stack[top++] = 0;
    while (top != 0) {
        const size_t island = stack[--top];
        for (size_t edge = 0; edge < solver->edge_count; ++edge) {
            bool usable = edge <= assigned_through && solver->multiplicity[edge] != 0;
            if (edge > assigned_through) {
                usable = true;
                for (size_t fixed = 0; fixed <= assigned_through; ++fixed) {
                    if (solver->multiplicity[fixed] != 0 && edges_cross(solver, fixed, edge)) {
                        usable = false;
                        break;
                    }
                }
            }
            if (!usable) continue;
            size_t neighbor = solver->island_count;
            if (solver->edge_u[edge] == island) neighbor = solver->edge_v[edge];
            else if (solver->edge_v[edge] == island) neighbor = solver->edge_u[edge];
            if (neighbor < solver->island_count && !reached[neighbor]) {
                reached[neighbor] = true;
                stack[top++] = neighbor;
            }
        }
    }
    for (size_t island = 0; island < solver->island_count; ++island)
        if (!reached[island]) return false;
    return true;
}

static bool residuals_feasible(const Solver *solver)
{
    for (size_t island = 0; island < solver->island_count; ++island)
        if (solver->residual[island] < 0 ||
            (uint64_t)solver->residual[island] > 2u * solver->remaining[island]) return false;
    return true;
}

static bool search(Solver *solver, size_t depth)
{
    if (depth == solver->edge_count) {
        for (size_t island = 0; island < solver->island_count; ++island)
            if (solver->residual[island] != 0) return false;
        if (!possible_graph_connected(solver, solver->edge_count - 1)) return false;
        for (size_t edge = 0; edge < solver->edge_count; ++edge)
            solver->solution[edge] = solver->multiplicity[edge];
        return true;
    }

    const size_t u = solver->edge_u[depth], v = solver->edge_v[depth];
    --solver->remaining[u];
    --solver->remaining[v];
    for (uint8_t amount = 0; amount <= 2; ++amount) {
        if (amount > solver->residual[u] || amount > solver->residual[v]) continue;
        bool crosses_used_edge = false;
        if (amount != 0) {
            for (size_t prior = 0; prior < depth; ++prior) {
                if (solver->multiplicity[prior] != 0 && edges_cross(solver, prior, depth)) {
                    crosses_used_edge = true;
                    break;
                }
            }
        }
        if (crosses_used_edge) continue;
        solver->multiplicity[depth] = amount;
        solver->residual[u] -= amount;
        solver->residual[v] -= amount;
        if (residuals_feasible(solver) &&
            possible_graph_connected(solver, depth) && search(solver, depth + 1)) {
            solver->residual[u] += amount;
            solver->residual[v] += amount;
            ++solver->remaining[u];
            ++solver->remaining[v];
            return true;
        }
        solver->residual[u] += amount;
        solver->residual[v] += amount;
        solver->multiplicity[depth] = 0;
    }
    ++solver->remaining[u];
    ++solver->remaining[v];
    return false;
}

int64_t hashiwokakero_small_solver(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 2 || input[0] > MAX_ISLANDS) return -1;
    const size_t island_count = (size_t)input[0];
    if (length != 1 + 3 * island_count) return -1;

    Solver solver = {0};
    solver.island_count = island_count;
    for (size_t island = 0; island < island_count; ++island) {
        const int64_t x = input[1 + 3 * island];
        const int64_t y = input[2 + 3 * island];
        const int64_t demand = input[3 + 3 * island];
        if (x < 0 || x > 7 || y < 0 || y > 7 || demand < 1 || demand > 8) return -1;
        for (size_t prior = 0; prior < island; ++prior)
            if (solver.x[prior] == x && solver.y[prior] == y) return -1;
        solver.x[island] = x;
        solver.y[island] = y;
        solver.residual[island] = demand;
    }

    for (size_t first = 0; first < island_count; ++first) {
        for (size_t second = first + 1; second < island_count; ++second) {
            if (solver.x[first] != solver.x[second] && solver.y[first] != solver.y[second]) continue;
            bool blocked = false;
            for (size_t middle = 0; middle < island_count; ++middle) {
                if (middle == first || middle == second) continue;
                if (solver.y[first] == solver.y[second] && solver.y[middle] == solver.y[first] &&
                    ((solver.x[first] < solver.x[middle] && solver.x[middle] < solver.x[second]) ||
                     (solver.x[second] < solver.x[middle] && solver.x[middle] < solver.x[first]))) blocked = true;
                if (solver.x[first] == solver.x[second] && solver.x[middle] == solver.x[first] &&
                    ((solver.y[first] < solver.y[middle] && solver.y[middle] < solver.y[second]) ||
                     (solver.y[second] < solver.y[middle] && solver.y[middle] < solver.y[first]))) blocked = true;
            }
            if (!blocked) {
                if (solver.edge_count == MAX_EDGE_SLOTS) return -1;
                const size_t edge = solver.edge_count++;
                solver.edge_u[edge] = first;
                solver.edge_v[edge] = second;
                ++solver.remaining[first];
                ++solver.remaining[second];
            }
        }
    }

    if (!search(&solver, 0)) return -2;
    uint64_t result = UINT64_C(1) << 32;
    for (size_t edge = 0; edge < solver.edge_count; ++edge)
        result |= (uint64_t)solver.solution[edge] << (2 * edge);
    return (int64_t)result;
}

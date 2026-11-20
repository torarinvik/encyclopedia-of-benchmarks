#include <array>
#include <cstddef>
#include <cstdint>
#include <initializer_list>

namespace {
constexpr int max_n = 8;
constexpr std::size_t max_parseable_length = 10;
constexpr std::size_t max_states = 59049;

struct Solver {
    int n{};
    std::array<int, max_n> top{};
    std::array<int, max_n> top_vertex{};
    std::array<std::array<bool, max_n>, max_n> adjacent{};
    std::array<std::int64_t, max_states> ways{};

    int triple_case(int i, int j, int k) const {
        const auto a = top[i], b = top[j], c = top[k];
        if (a < b && b < c) return 1;
        if (a < c && c < b) return 2;
        if (b < a && a < c) return 3;
        if (b < c && c < a) return 4;
        if (c < a && a < b) return 5;
        return 0;
    }

    bool covered(int y, const int *set, int size) const {
        for (int z = 0; z < size; ++z) if (adjacent[set[z]][y]) return true;
        return false;
    }

    bool irredundant(const int *set, int size) const {
        for (int x = 0; x < size; ++x) {
            bool private_neighbor = false;
            for (int y = 0; y < n && !private_neighbor; ++y) {
                if (!adjacent[set[x]][y]) continue;
                bool shared = false;
                for (int z = 0; z < size; ++z)
                    if (z != x && adjacent[set[z]][y]) { shared = true; break; }
                private_neighbor = !shared;
            }
            if (!private_neighbor) return false;
        }
        return true;
    }

    int private_min_rank(int x, const int *set, int size) const {
        int best = -1;
        for (int y = 0; y < n; ++y) {
            if (!adjacent[x][y]) continue;
            bool shared = false;
            for (int z = 0; z < size; ++z)
                if (set[z] != x && adjacent[set[z]][y]) { shared = true; break; }
            if (!shared && (best < 0 || top[y] < top[best])) best = y;
        }
        return best;
    }

    bool initial(int i, int j, int k, int r, int s) const {
        const int tri[3] = {i, j, k};
        if (r != n || !irredundant(tri, 3)) return false;
        switch (triple_case(i, j, k)) {
        case 1:
            for (int y = 0; y < n; ++y) if (y < i && top[y] < top[i]) return false;
            return s == private_min_rank(i, tri, 3);
        case 2:
            if (s != n) return false;
            for (int y = 0; y < n; ++y)
                if (top[y] < top[k] && y < j && !covered(y, tri, 3)) return false;
            return true;
        case 3:
            for (int y = 0; y < n; ++y) if (top[y] < top[j] && y < i) return false;
            return s == private_min_rank(j, tri, 3);
        case 4:
            if (s != n) return false;
            for (int y = 0; y < n; ++y)
                if (top[y] < top[j] && y < i && !covered(y, tri, 3)) return false;
            return true;
        case 5:
            for (int y = 0; y < n; ++y) if (top[y] < top[k] && y < i) return false;
            return s == private_min_rank(k, tri, 3);
        default: return false;
        }
    }

    bool regular(int i, int j, int k, int r, int s) const {
        const int tri[3] = {i, j, k};
        if (!irredundant(tri, 3)) return false;
        const int kind = triple_case(i, j, k);
        if (kind >= 1 && kind <= 4) {
            if (r < 0 || r >= i) return false;
        } else if (kind == 5) {
            if (r != n) return false;
        } else return false;
        if (kind == 2 || kind == 4) return s == n;
        if (s < 0 || s >= n) return false;
        if (kind == 1)
            return adjacent[i][s] && !adjacent[r][s] && !adjacent[j][s] && !adjacent[k][s];
        if (kind == 3)
            return adjacent[j][s] && !adjacent[r][s] && !adjacent[i][s] && !adjacent[k][s];
        return adjacent[k][s] && !adjacent[i][s] && !adjacent[j][s];
    }

    bool final_state(int i, int j, int k, int r) const {
        int set[4], size = 0;
        if (r != n) set[size++] = r;
        set[size++] = i; set[size++] = j; set[size++] = k;
        for (int y = 0; y < n; ++y)
            if (i < y && top[i] < top[y] && !covered(y, set, size)) return false;
        return true;
    }

    static std::size_t index(int i, int j, int k, int r, int s, int base) {
        std::size_t id = static_cast<std::size_t>(i);
        for (int field : {j, k, r, s}) id = id * static_cast<std::size_t>(base) + static_cast<std::size_t>(field);
        return id;
    }

    bool successor(int i, int j, int k, int r, int s, int ell, int &new_r, int &new_s) const {
        const int kind = triple_case(j, k, ell);
        if (!kind) return false;
        int selected[5], size = 0;
        if (r != n) selected[size++] = r;
        selected[size++] = i; selected[size++] = j; selected[size++] = k; selected[size++] = ell;
        if (!irredundant(selected, size)) return false;
        if (s != n && top[ell] <= top[s]) return false;
        if (!adjacent[j][k])
            for (int y = 0; y < n; ++y)
                if (i < y && y < j && top[i] < top[y] && top[y] < top[j] && !covered(y, selected, size)) return false;
        if (adjacent[i][k])
            for (int y = 0; y < n; ++y)
                if (j < y && y < k && top[j] < top[y] && top[y] < top[ell] && !covered(y, selected, size)) return false;
        if (kind == 5) new_r = n;
        else {
            int highest = top[i];
            if (r != n && top[r] > highest) highest = top[r];
            new_r = top_vertex[highest];
        }
        if (kind == 2 || kind == 4) new_s = n;
        else {
            const int old_min = top[i] < top[j] ? (top[i] < top[k] ? top[i] : top[k]) : (top[j] < top[k] ? top[j] : top[k]);
            const int new_min = top[j] < top[k] ? (top[j] < top[ell] ? top[j] : top[ell]) : (top[k] < top[ell] ? top[k] : top[ell]);
            if (s != n && old_min == new_min) new_s = s;
            else {
                int y = j;
                if (top[k] < top[y]) y = k;
                if (top[ell] < top[y]) y = ell;
                new_s = private_min_rank(y, selected, size);
                if (new_s < 0) return false;
            }
        }
        return regular(j, k, ell, new_r, new_s);
    }

    bool dominates(std::uint32_t mask, const std::array<std::uint32_t, max_n> &hoods) const {
        std::uint32_t covered_mask = 0;
        for (int x = 0; x < n; ++x) if (mask & (1u << x)) covered_mask |= hoods[x];
        return covered_mask == ((1u << n) - 1u);
    }

    std::int64_t count() {
        const int base = n + 1;
        std::int64_t answer = 0;
        for (int i = n - 3; i >= 0; --i)
            for (int j = i + 1; j < n - 1; ++j)
                for (int k = j + 1; k < n; ++k) {
                    const int tri[3] = {i, j, k};
                    if (!triple_case(i, j, k) || !irredundant(tri, 3)) continue;
                    for (int ri = 0; ri <= i; ++ri) {
                        const int r = ri == i ? n : ri;
                        for (int s = 0; s <= n; ++s) {
                            if (!initial(i, j, k, r, s) && !regular(i, j, k, r, s)) continue;
                            std::int64_t paths = final_state(i, j, k, r) ? 1 : 0;
                            for (int ell = k + 1; ell < n; ++ell) {
                                int nr, ns;
                                if (successor(i, j, k, r, s, ell, nr, ns)) paths += ways[index(j, k, ell, nr, ns, base)];
                            }
                            ways[index(i, j, k, r, s, base)] = paths;
                            if (initial(i, j, k, r, s)) answer += paths;
                        }
                    }
                }
        std::array<std::uint32_t, max_n> hoods{};
        for (int x = 0; x < n; ++x)
            for (int y = 0; y < n; ++y) if (adjacent[x][y]) hoods[x] |= 1u << y;
        const std::uint32_t full = (1u << n) - 1u;
        for (std::uint32_t mask = 1; mask <= full; ++mask) {
            int size = 0;
            for (std::uint32_t bits = mask; bits; bits >>= 1) size += static_cast<int>(bits & 1u);
            if (size > 2 || !dominates(mask, hoods)) continue;
            bool minimal = true;
            for (int x = 0; x < n; ++x)
                if ((mask & (1u << x)) && dominates(mask ^ (1u << x), hoods)) minimal = false;
            if (minimal) ++answer;
        }
        return answer;
    }
};
} // namespace

extern "C" std::int64_t minimal_dominating_sets_permutation_graphs(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (input[0] < 1 || input[0] > max_n) return -1;
    Solver solver{};
    solver.n = static_cast<int>(input[0]);
    if (length != static_cast<std::size_t>(solver.n + 1)) return -1;
    for (int x = 0; x < solver.n; ++x) {
        const std::int64_t rank = input[x + 1];
        if (rank < 0 || rank >= solver.n) return -1;
        solver.top[x] = static_cast<int>(rank);
        for (int y = 0; y < x; ++y) if (solver.top[y] == solver.top[x]) return -1;
        solver.top_vertex[solver.top[x]] = x;
        solver.adjacent[x][x] = true;
    }
    for (int x = 0; x < solver.n; ++x)
        for (int y = x + 1; y < solver.n; ++y)
            solver.adjacent[x][y] = solver.adjacent[y][x] = solver.top[x] > solver.top[y];
    return solver.count();
}

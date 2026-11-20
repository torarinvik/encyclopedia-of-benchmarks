// Clean-room McCreight radix priority-search-tree profile.
#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

extern "C" std::int64_t priority_search_tree_three_sided_reporting(const std::int64_t* input, std::size_t length) {
    constexpr int max_n = 8, max_q = 7, x_domain = 32;
    if (input == nullptr || length < 2 || length > 48) return -1;
    const auto n64 = input[0], q64 = input[1];
    if (n64 < 0 || n64 > max_n || q64 < 0 || q64 > max_q || length != 2 + 3 * static_cast<std::size_t>(n64) + 3 * static_cast<std::size_t>(q64)) return -1;
    const int n = static_cast<int>(n64), q = static_cast<int>(q64);
    std::array<int, max_n> nx{}, ny{}, nl{}, left{}, right{}, nlo{}, nhi{};
    std::array<bool, x_domain> seen_x{};
    std::array<bool, max_n> seen_label{};
    left.fill(-1); right.fill(-1);
    int root = -1, count = 0;
    std::size_t at = 2;
    for (int r = 0; r < n; ++r) {
        const auto x64 = input[at++], y64 = input[at++], label64 = input[at++];
        if (x64 < 0 || x64 >= x_domain || y64 < -64 || y64 > 63 || label64 < 0 || label64 >= max_n || seen_x[static_cast<std::size_t>(x64)] || seen_label[static_cast<std::size_t>(label64)]) return -1;
        seen_x[static_cast<std::size_t>(x64)] = true; seen_label[static_cast<std::size_t>(label64)] = true;
        int px = static_cast<int>(x64), py = static_cast<int>(y64), pl = static_cast<int>(label64);
        if (root < 0) { root = count++; nx[root] = px; ny[root] = py; nl[root] = pl; nlo[root] = 0; nhi[root] = x_domain; continue; }
        int cur = root, low = 0, high = x_domain;
        for (;;) {
            if (py < ny[cur]) { std::swap(px, nx[cur]); std::swap(py, ny[cur]); std::swap(pl, nl[cur]); }
            const int mid = (low + high) / 2;
            if (px < mid) {
                if (left[cur] < 0) { const int child = count++; left[cur] = child; nx[child] = px; ny[child] = py; nl[child] = pl; nlo[child] = low; nhi[child] = mid; break; }
                cur = left[cur]; high = mid;
            } else {
                if (right[cur] < 0) { const int child = count++; right[cur] = child; nx[child] = px; ny[child] = py; nl[child] = pl; nlo[child] = mid; nhi[child] = high; break; }
                cur = right[cur]; low = mid;
            }
        }
    }
    std::array<int, max_q> qx0{}, qx1{}, qy1{};
    for (int i = 0; i < q; ++i) {
        const auto x0 = input[at++], x1 = input[at++], y1 = input[at++];
        if (x0 < 0 || x0 > x1 || x1 >= x_domain || y1 < -64 || y1 > 63) return -1;
        qx0[i] = static_cast<int>(x0); qx1[i] = static_cast<int>(x1); qy1[i] = static_cast<int>(y1);
    }
    std::int64_t result = 0;
    for (int qi = 0; qi < q; ++qi) {
        std::uint16_t mask = 0;
        if (root >= 0) {
            std::array<int, max_n> stack{}; int top = 0; stack[top++] = root;
            while (top > 0) {
                const int node = stack[--top];
                if (qx1[qi] < nlo[node] || qx0[qi] >= nhi[node] || ny[node] > qy1[qi]) continue;
                if (qx0[qi] <= nx[node] && nx[node] <= qx1[qi]) mask |= static_cast<std::uint16_t>(1u << nl[node]);
                if (left[node] >= 0) stack[top++] = left[node];
                if (right[node] >= 0) stack[top++] = right[node];
            }
        }
        result |= static_cast<std::int64_t>(mask) << (8 * qi);
    }
    return result;
}

#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_N = 8;
constexpr std::size_t MAX_LEN = 35;
constexpr int INF = 1000000;

struct Tree { int n{}; int labels[MAX_N]{}; int children[MAX_N][MAX_N]{}; int child_count[MAX_N]{}; };
struct Post { int n{}; int labels[MAX_N + 1]{}; int leftmost[MAX_N + 1]{}; };

int post_visit(const Tree& tree, int vertex, Post& post) {
    int left = 0;
    for (int k = 0; k < tree.child_count[vertex]; ++k) {
        const int child_left = post_visit(tree, tree.children[vertex][k], post);
        if (k == 0) left = child_left;
    }
    const int id = ++post.n;
    post.labels[id] = tree.labels[vertex];
    post.leftmost[id] = left == 0 ? id : left;
    return post.leftmost[id];
}

bool read_tree(const std::int64_t* input, std::size_t& position, int n, Tree& tree) {
    tree.n = n;
    for (int v = 0; v < n; ++v) {
        const auto label = input[position++];
        if (label < 0 || label > 3) return false;
        tree.labels[v] = static_cast<int>(label);
    }
    int stack[MAX_N]{}; int top = 0;
    for (int v = 0; v < n; ++v) {
        const auto parent = input[position++];
        if (v == 0) { if (parent != -1) return false; stack[0] = 0; continue; }
        if (parent < 0 || parent >= v) return false;
        while (top >= 0 && stack[top] != parent) --top;
        if (top < 0) return false;
        const int p = static_cast<int>(parent);
        tree.children[p][tree.child_count[p]++] = v;
        stack[++top] = v;
    }
    return true;
}

int distance(const Tree& a, const Tree& b) {
    Post pa{}, pb{};
    post_visit(a, 0, pa); post_visit(b, 0, pb);
    int key_a[MAX_N + 1]{}, key_b[MAX_N + 1]{};
    for (int i = 1; i <= pa.n; ++i) key_a[pa.leftmost[i]] = i;
    for (int j = 1; j <= pb.n; ++j) key_b[pb.leftmost[j]] = j;
    int td[MAX_N + 1][MAX_N + 1]{};
    for (int ra = 1; ra <= pa.n; ++ra) {
        if (key_a[pa.leftmost[ra]] != ra) continue;
        for (int rb = 1; rb <= pb.n; ++rb) {
            if (key_b[pb.leftmost[rb]] != rb) continue;
            const int sa = pa.leftmost[ra], sb = pb.leftmost[rb];
            int fd[MAX_N + 1][MAX_N + 1];
            for (auto& row : fd) for (int& value : row) value = INF;
            fd[sa - 1][sb - 1] = 0;
            for (int x = sa; x <= ra; ++x) fd[x][sb - 1] = fd[x - 1][sb - 1] + 1;
            for (int y = sb; y <= rb; ++y) fd[sa - 1][y] = fd[sa - 1][y - 1] + 1;
            for (int x = sa; x <= ra; ++x) for (int y = sb; y <= rb; ++y) {
                const int del = fd[x - 1][y] + 1, ins = fd[x][y - 1] + 1;
                if (pa.leftmost[x] == sa && pb.leftmost[y] == sb) {
                    const int rename = fd[x - 1][y - 1] + (pa.labels[x] != pb.labels[y]);
                    const int value = del < ins ? (del < rename ? del : rename) : (ins < rename ? ins : rename);
                    fd[x][y] = value; td[x][y] = value;
                } else {
                    const int join = fd[pa.leftmost[x] - 1][pb.leftmost[y] - 1] + td[x][y];
                    fd[x][y] = del < ins ? (del < join ? del : join) : (ins < join ? ins : join);
                }
            }
        }
    }
    return td[pa.n][pb.n];
}
}

extern "C" std::int64_t ordered_tree_edit_distance_zhang_shasha(
    const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 6 || length > MAX_LEN) return -1;
    const auto n1v = input[0], n2v = input[1];
    if (n1v < 1 || n1v > MAX_N || n2v < 1 || n2v > MAX_N) return -1;
    const int n1 = static_cast<int>(n1v), n2 = static_cast<int>(n2v);
    if (length != static_cast<std::size_t>(2 + 2 * n1 + 2 * n2)) return -1;
    std::size_t position = 2; Tree a{}, b{};
    if (!read_tree(input, position, n1, a) || !read_tree(input, position, n2, b)) return -1;
    return distance(a, b);
}

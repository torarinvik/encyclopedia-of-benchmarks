#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_LEN = 35, INF = 1000000 };

typedef struct {
    int n;
    int labels[MAX_N];
    int children[MAX_N][MAX_N];
    int child_count[MAX_N];
} Tree;

typedef struct {
    int n;
    int labels[MAX_N + 1];
    int leftmost[MAX_N + 1];
} Postorder;

static int postorder_visit(const Tree *tree, int vertex, Postorder *post) {
    int left = 0;
    for (int k = 0; k < tree->child_count[vertex]; ++k) {
        int child_left = postorder_visit(tree, tree->children[vertex][k], post);
        if (k == 0) left = child_left;
    }
    const int id = ++post->n;
    post->labels[id] = tree->labels[vertex];
    post->leftmost[id] = left == 0 ? id : left;
    return post->leftmost[id];
}

static int read_tree(const int64_t *input, size_t *position, int n, Tree *tree) {
    tree->n = n;
    for (int v = 0; v < n; ++v) {
        const int64_t label = input[(*position)++];
        if (label < 0 || label > 3) return 0;
        tree->labels[v] = (int)label;
    }
    int stack[MAX_N];
    int top = 0;
    stack[0] = 0;
    for (int v = 0; v < n; ++v) {
        const int64_t parent = input[(*position)++];
        if (v == 0) {
            if (parent != -1) return 0;
            continue;
        }
        if (parent < 0 || parent >= v) return 0;
        while (top >= 0 && stack[top] != parent) --top;
        if (top < 0) return 0;
        const int p = (int)parent;
        tree->children[p][tree->child_count[p]++] = v;
        stack[++top] = v;
    }
    return 1;
}

static int tree_edit_distance(const Tree *a, const Tree *b) {
    Postorder pa = {0}, pb = {0};
    postorder_visit(a, 0, &pa);
    postorder_visit(b, 0, &pb);
    int key_a[MAX_N + 1] = {0}, key_b[MAX_N + 1] = {0};
    for (int i = 1; i <= pa.n; ++i) key_a[pa.leftmost[i]] = i;
    for (int j = 1; j <= pb.n; ++j) key_b[pb.leftmost[j]] = j;
    int td[MAX_N + 1][MAX_N + 1] = {{0}};
    for (int root_a = 1; root_a <= pa.n; ++root_a) {
        if (key_a[pa.leftmost[root_a]] != root_a) continue;
        for (int root_b = 1; root_b <= pb.n; ++root_b) {
            if (key_b[pb.leftmost[root_b]] != root_b) continue;
            const int start_a = pa.leftmost[root_a], start_b = pb.leftmost[root_b];
            int fd[MAX_N + 1][MAX_N + 1];
            for (int x = 0; x <= MAX_N; ++x)
                for (int y = 0; y <= MAX_N; ++y) fd[x][y] = INF;
            fd[start_a - 1][start_b - 1] = 0;
            for (int x = start_a; x <= root_a; ++x) fd[x][start_b - 1] = fd[x - 1][start_b - 1] + 1;
            for (int y = start_b; y <= root_b; ++y) fd[start_a - 1][y] = fd[start_a - 1][y - 1] + 1;
            for (int x = start_a; x <= root_a; ++x) {
                for (int y = start_b; y <= root_b; ++y) {
                    const int del = fd[x - 1][y] + 1;
                    const int ins = fd[x][y - 1] + 1;
                    if (pa.leftmost[x] == start_a && pb.leftmost[y] == start_b) {
                        const int rename = fd[x - 1][y - 1] + (pa.labels[x] != pb.labels[y]);
                        int best = del < ins ? del : ins;
                        if (rename < best) best = rename;
                        fd[x][y] = best;
                        td[x][y] = best;
                    } else {
                        const int join = fd[pa.leftmost[x] - 1][pb.leftmost[y] - 1] + td[x][y];
                        int best = del < ins ? del : ins;
                        if (join < best) best = join;
                        fd[x][y] = best;
                    }
                }
            }
        }
    }
    return td[pa.n][pb.n];
}

int64_t ordered_tree_edit_distance_zhang_shasha(const int64_t *input, size_t length) {
    if (input == NULL || length < 6 || length > MAX_LEN) return -1;
    const int64_t n1v = input[0], n2v = input[1];
    if (n1v < 1 || n1v > MAX_N || n2v < 1 || n2v > MAX_N) return -1;
    const int n1 = (int)n1v, n2 = (int)n2v;
    if (length != (size_t)(2 + 2 * n1 + 2 * n2)) return -1;
    size_t position = 2;
    Tree a = {0}, b = {0};
    if (!read_tree(input, &position, n1, &a) || !read_tree(input, &position, n2, &b)) return -1;
    return tree_edit_distance(&a, &b);
}

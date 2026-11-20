/* Pagoda priority queue with two parent/extreme-leaf links per node. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_QUEUES 8
#define MAX_OPERATIONS 64
#define MAX_PARSEABLE_WORDS 259
#define NIL INT64_C(-1)

static int branch_stack(int64_t root, bool right_branch, int64_t node_count,
                        const int64_t *leftmost, const int64_t *rightmost,
                        int64_t *stack)
{
    int64_t node = right_branch ? rightmost[root] : leftmost[root];
    if (node < 0 || node >= node_count) return -1;
    int count = 0;
    while (count < node_count) {
        stack[count++] = node;
        if (node == root) return count;
        node = right_branch ? rightmost[node] : leftmost[node];
        if (node < 0 || node >= node_count) return -1;
    }
    return -1;
}

static int64_t pagoda_meld(int64_t g_root, int64_t d_root, int64_t node_count,
                           const int64_t *keys, int64_t *leftmost, int64_t *rightmost)
{
    if (g_root < 0) return d_root;
    if (d_root < 0) return g_root;

    int64_t g_branch[MAX_OPERATIONS];
    int64_t d_branch[MAX_OPERATIONS];
    int g_count = branch_stack(g_root, true, node_count, leftmost, rightmost, g_branch);
    int d_count = branch_stack(d_root, false, node_count, leftmost, rightmost, d_branch);
    if (g_count < 1 || d_count < 1) return -2;

    int gi = 0, di = 0;
    int64_t central = NIL, central_left = NIL, central_right = NIL;
    while (gi < g_count || di < d_count) {
        bool take_g = di >= d_count ||
                      (gi < g_count && keys[g_branch[gi]] > keys[d_branch[di]]);
        int64_t node;
        int64_t kept_extreme;
        if (take_g) {
            node = g_branch[gi++];
            kept_extreme = leftmost[node];
        } else {
            node = d_branch[di++];
            kept_extreme = rightmost[node];
        }

        if (central >= 0) {
            if (take_g) {
                /* A G node makes the accumulated subtree its right child. */
                rightmost[central] = node;
                leftmost[central] = central_left == central ? NIL : central_left;
            } else {
                /* A D node makes the accumulated subtree its left child. */
                leftmost[central] = node;
                rightmost[central] = central_right == central ? NIL : central_right;
            }
        }

        int64_t new_left, new_right;
        if (take_g) {
            new_left = kept_extreme < 0 ? node : kept_extreme;
            new_right = central >= 0 ? central_right : node;
        } else {
            new_left = central >= 0 ? central_left : node;
            new_right = kept_extreme < 0 ? node : kept_extreme;
        }
        leftmost[node] = new_left;
        rightmost[node] = new_right;
        central = node;
        central_left = new_left;
        central_right = new_right;
    }
    return central;
}

static int64_t pagoda_extract_min(int64_t root, int64_t node_count,
                                  const int64_t *keys, int64_t *leftmost,
                                  int64_t *rightmost)
{
    int64_t old_leftmost = leftmost[root];
    int64_t old_rightmost = rightmost[root];
    int64_t left_child = NIL, right_child = NIL;

    if (old_leftmost != root) {
        int64_t node = old_leftmost;
        int steps = 0;
        while (node >= 0 && node < node_count && leftmost[node] != root && steps++ < node_count)
            node = leftmost[node];
        if (node < 0 || node >= node_count || leftmost[node] != root) return -2;
        left_child = node;
    }
    if (old_rightmost != root) {
        int64_t node = old_rightmost;
        int steps = 0;
        while (node >= 0 && node < node_count && rightmost[node] != root && steps++ < node_count)
            node = rightmost[node];
        if (node < 0 || node >= node_count || rightmost[node] != root) return -2;
        right_child = node;
    }

    /* Promote both subtrees to roots, recovering the opposite extreme from
       the removed root's branch links. */
    if (left_child >= 0) {
        leftmost[left_child] = old_leftmost;
        if (rightmost[left_child] < 0) rightmost[left_child] = left_child;
    }
    if (right_child >= 0) {
        rightmost[right_child] = old_rightmost;
        if (leftmost[right_child] < 0) leftmost[right_child] = right_child;
    }

    /* The paper names this D+G: the right subtree is melded before the left. */
    int64_t new_root = pagoda_meld(right_child, left_child, node_count,
                                   keys, leftmost, rightmost);
    leftmost[root] = NIL;
    rightmost[root] = NIL;
    return new_root;
}

int64_t pagoda_meldable_priority_queue(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_WORDS) return -1;
    int64_t raw_queues = input[0], raw_operations = input[1];
    if (raw_queues < 1 || raw_queues > MAX_QUEUES ||
        raw_operations < 0 || raw_operations > MAX_OPERATIONS ||
        length != (size_t)(2 + 4 * raw_operations) || length > 258) return -1;

    int64_t keys[MAX_OPERATIONS] = {0};
    int64_t leftmost[MAX_OPERATIONS];
    int64_t rightmost[MAX_OPERATIONS];
    int64_t roots[MAX_QUEUES];
    for (int i = 0; i < MAX_OPERATIONS; ++i) leftmost[i] = rightmost[i] = NIL;
    for (int i = 0; i < MAX_QUEUES; ++i) roots[i] = NIL;

    int64_t node_count = 0;
    int64_t result = 0;
    for (int64_t op = 0; op < raw_operations; ++op) {
        size_t offset = (size_t)(2 + 4 * op);
        int64_t opcode = input[offset];
        int64_t first = input[offset + 1];
        int64_t second = input[offset + 2];
        int64_t priority = input[offset + 3];
        if (opcode == 1) {
            if (first < 0 || first >= raw_queues || second != 0 ||
                priority < -1000 || priority > 1000 || node_count >= MAX_OPERATIONS)
                return -1;
            for (int64_t i = 0; i < node_count; ++i)
                if (keys[i] == priority) return -1;
            int64_t node = node_count++;
            keys[node] = priority;
            leftmost[node] = rightmost[node] = node;
            int64_t merged = pagoda_meld(roots[first], node, node_count,
                                         keys, leftmost, rightmost);
            if (merged < 0) return -1;
            roots[first] = merged;
        } else if (opcode == 2) {
            if (first < 0 || first >= raw_queues || second < 0 || second >= raw_queues ||
                first == second || priority != 0) return -1;
            int64_t merged = pagoda_meld(roots[first], roots[second], node_count,
                                         keys, leftmost, rightmost);
            if (merged == -2) return -1;
            roots[first] = merged;
            roots[second] = NIL;
        } else if (opcode == 3 || opcode == 4) {
            if (first < 0 || first >= raw_queues || second != 0 || priority != 0 ||
                roots[first] < 0) return -1;
            int64_t root = roots[first];
            result += (op + 1) * (keys[root] + 1001);
            if (opcode == 4) {
                int64_t new_root = pagoda_extract_min(root, node_count,
                                                      keys, leftmost, rightmost);
                if (new_root == -2) return -1;
                roots[first] = new_root;
            }
        } else {
            return -1;
        }
    }
    return result;
}

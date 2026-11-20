#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr int MaxN = 20, MaxM = 32, MaxInput = 35, ArenaSize = 128, MaxOutput = 648;
enum : std::uint8_t { Leaf = 0, PNode = 1, QNode = 2, White = 0, Black = 1, Mixed = 2 };
struct Node { std::uint8_t kind = 0, count = 0, arg = 0; std::array<std::uint8_t, MaxN> child{}; };
struct Tree {
    std::array<Node, ArenaSize> nodes{};
    std::array<std::uint8_t, ArenaSize> color{}, freeId{};
    int nextId = 0, freeCount = 0, root = 0;
};

int create(Tree& tree, int kind) {
    int id;
    if (tree.freeCount) id = tree.freeId[--tree.freeCount];
    else { if (tree.nextId >= ArenaSize) return -1; id = tree.nextId++; }
    tree.nodes[id] = Node{};
    tree.nodes[id].kind = static_cast<std::uint8_t>(kind);
    return id;
}
void discard(Tree& tree, int id) {
    tree.nodes[id].count = 0;
    tree.freeId[tree.freeCount++] = static_cast<std::uint8_t>(id);
}
void push(Tree& tree, int id, int child) {
    Node& node = tree.nodes[id];
    node.child[node.count++] = static_cast<std::uint8_t>(child);
}

int paint(Tree& tree, int id, std::uint64_t mask) {
    const Node node = tree.nodes[id];
    if (node.kind == Leaf) {
        tree.color[id] = static_cast<std::uint8_t>((mask >> node.arg) & 1u ? Black : White);
        return tree.color[id];
    }
    bool sawWhite = false, sawBlack = false;
    for (int i = 0; i < node.count; ++i) {
        const int shade = paint(tree, node.child[i], mask);
        sawWhite |= shade != Black;
        sawBlack |= shade != White;
    }
    tree.color[id] = static_cast<std::uint8_t>(sawWhite && sawBlack ? Mixed : sawBlack ? Black : White);
    return tree.color[id];
}

bool qPattern(const Tree& tree, const std::array<std::uint8_t, MaxN>& children, int count) {
    int pivot = -1, mixed = 0;
    for (int i = 0; i < count; ++i) if (tree.color[children[i]] == Mixed) {
        pivot = i;
        if (++mixed > 1) return false;
    }
    if (!mixed) for (int i = 0; i < count; ++i)
        if (tree.color[children[i]] == Black) { pivot = i; break; }
    if (pivot < 0) return false;
    for (int i = 0; i < pivot; ++i) if (tree.color[children[i]] != White) return false;
    for (int i = pivot + 1; i < count; ++i) if (tree.color[children[i]] != Black) return false;
    return true;
}

bool split(Tree& tree, int id, std::array<std::uint8_t, MaxN>& out, int& outCount) {
    const Node node = tree.nodes[id];
    if (tree.color[id] != Mixed) { out[0] = static_cast<std::uint8_t>(id); outCount = 1; return true; }
    auto old = node.child;
    std::array<std::uint8_t, MaxN> white{}, black{}, mixed{};
    int nw = 0, nb = 0, nm = 0, used = 0;
    for (int i = 0; i < node.count; ++i) {
        const auto child = old[i];
        const auto shade = tree.color[child];
        if (shade == White) white[nw++] = child;
        else if (shade == Black) black[nb++] = child;
        else mixed[nm++] = child;
    }
    if (node.kind == QNode) {
        if (!qPattern(tree, old, node.count)) {
            for (int left = 0, right = node.count - 1; left < right; ++left, --right)
                std::swap(old[left], old[right]);
            if (!qPattern(tree, old, node.count)) return false;
        }
        for (int i = 0; i < node.count; ++i) {
            const int child = old[i];
            if (tree.color[child] == Mixed) {
                std::array<std::uint8_t, MaxN> part{}; int partCount = 0;
                if (!split(tree, child, part, partCount)) return false;
                for (int j = 0; j < partCount; ++j) out[used++] = part[j];
            } else out[used++] = static_cast<std::uint8_t>(child);
        }
    } else {
        if (nm > 1) return false;
        if (nw) {
            const int group = create(tree, PNode); if (group < 0) return false;
            for (int i = 0; i < nw; ++i) push(tree, group, white[i]);
            out[used++] = static_cast<std::uint8_t>(group);
        }
        if (nm) {
            std::array<std::uint8_t, MaxN> part{}; int partCount = 0;
            if (!split(tree, mixed[0], part, partCount)) return false;
            for (int i = 0; i < partCount; ++i) out[used++] = part[i];
        }
        if (nb) {
            const int group = create(tree, PNode); if (group < 0) return false;
            for (int i = 0; i < nb; ++i) push(tree, group, black[i]);
            out[used++] = static_cast<std::uint8_t>(group);
        }
    }
    discard(tree, id);
    outCount = used;
    return true;
}

bool work(Tree& tree, int id) {
    const Node node = tree.nodes[id];
    if (tree.color[id] != Mixed) return true;
    std::array<std::uint8_t, MaxN> old{}, white{}, black{}, mixed{};
    int nw = 0, nb = 0, nm = 0;
    for (int i = 0; i < node.count; ++i) {
        old[i] = node.child[i];
        const auto shade = tree.color[old[i]];
        if (shade == White) white[nw++] = old[i];
        else if (shade == Black) black[nb++] = old[i];
        else mixed[nm++] = old[i];
    }
    if (node.kind == PNode) {
        if (!nb && nm == 1) return work(tree, mixed[0]);
        if (nm > 2) return false;
        const int q = create(tree, QNode); if (q < 0) return false;
        Node& root = tree.nodes[id];
        for (int i = 0; i < nw; ++i) root.child[i] = white[i];
        root.child[nw] = static_cast<std::uint8_t>(q);
        root.count = static_cast<std::uint8_t>(nw + 1);
        if (nm) {
            std::array<std::uint8_t, MaxN> part{}; int partCount = 0;
            if (!split(tree, mixed[0], part, partCount)) return false;
            for (int i = 0; i < partCount; ++i) push(tree, q, part[i]);
        }
        if (nb) {
            const int group = create(tree, PNode); if (group < 0) return false;
            for (int i = 0; i < nb; ++i) push(tree, group, black[i]);
            push(tree, q, group);
        }
        if (nm == 2) {
            std::array<std::uint8_t, MaxN> part{}; int partCount = 0;
            if (!split(tree, mixed[1], part, partCount)) return false;
            for (int i = partCount - 1; i >= 0; --i) push(tree, q, part[i]);
        }
        return true;
    }
    int left = -1, right = -1;
    for (int i = 0; i < node.count; ++i) if (tree.color[old[i]] != White) {
        if (left < 0) left = i;
        right = i;
    }
    if (left < 0) return false;
    for (int i = left + 1; i < right; ++i) if (tree.color[old[i]] != Black) return false;
    if (left == right && tree.color[old[left]] == Mixed) return work(tree, old[left]);
    std::array<std::uint8_t, MaxN> result{}; int used = 0;
    for (int i = 0; i < left; ++i) result[used++] = old[i];
    std::array<std::uint8_t, MaxN> part{}; int partCount = 0;
    if (!split(tree, old[left], part, partCount)) return false;
    for (int i = 0; i < partCount; ++i) result[used++] = part[i];
    for (int i = left + 1; i < right; ++i) result[used++] = old[i];
    if (right != left) {
        partCount = 0;
        if (!split(tree, old[right], part, partCount)) return false;
        for (int i = partCount - 1; i >= 0; --i) result[used++] = part[i];
    }
    for (int i = right + 1; i < node.count; ++i) result[used++] = old[i];
    tree.nodes[id].count = static_cast<std::uint8_t>(used);
    for (int i = 0; i < used; ++i) tree.nodes[id].child[i] = result[i];
    return true;
}

int normalize(Tree& tree, int id) {
    Node node = tree.nodes[id];
    if (node.kind == Leaf) return id;
    for (int i = 0; i < node.count; ++i)
        tree.nodes[id].child[i] = static_cast<std::uint8_t>(normalize(tree, node.child[i]));
    node = tree.nodes[id];
    if (node.count == 1) { const int child = node.child[0]; discard(tree, id); return child; }
    if (node.kind == QNode && node.count == 2) tree.nodes[id].kind = PNode;
    return id;
}

int compare(const Tree& tree, int a, int b) {
    const Node& left = tree.nodes[a]; const Node& right = tree.nodes[b];
    const int la = left.kind == Leaf ? left.arg : left.count;
    const int ra = right.kind == Leaf ? right.arg : right.count;
    if (left.kind != right.kind) return left.kind < right.kind ? -1 : 1;
    if (la != ra) return la < ra ? -1 : 1;
    if (left.kind == Leaf) return 0;
    for (int i = 0; i < left.count; ++i) {
        const int result = compare(tree, left.child[i], right.child[i]);
        if (result) return result;
    }
    return 0;
}
void canonicalize(Tree& tree, int id) {
    Node node = tree.nodes[id]; if (node.kind == Leaf) return;
    for (int i = 0; i < node.count; ++i) canonicalize(tree, node.child[i]);
    if (node.kind == PNode) {
        for (int i = 1; i < node.count; ++i) {
            const auto item = tree.nodes[id].child[i]; int j = i;
            while (j && compare(tree, item, tree.nodes[id].child[j - 1]) < 0) {
                tree.nodes[id].child[j] = tree.nodes[id].child[j - 1]; --j;
            }
            tree.nodes[id].child[j] = item;
        }
    } else {
        int order = 0;
        for (int i = 0; i < node.count; ++i) {
            order = compare(tree, node.child[i], node.child[node.count - 1 - i]);
            if (order) break;
        }
        if (order > 0) for (int left = 0, right = node.count - 1; left < right; ++left, --right)
            std::swap(tree.nodes[id].child[left], tree.nodes[id].child[right]);
    }
}
std::int64_t frontierCount(const Tree& tree, int id) {
    const Node& node = tree.nodes[id]; if (node.kind == Leaf) return 1;
    std::int64_t result = 1;
    for (int i = 0; i < node.count; ++i) result *= frontierCount(tree, node.child[i]);
    if (node.kind == PNode) for (int i = 2; i <= node.count; ++i) result *= i;
    else result *= 2;
    return result;
}
int nodeCount(const Tree& tree, int id) {
    const Node& node = tree.nodes[id]; int result = 1;
    if (node.kind != Leaf) for (int i = 0; i < node.count; ++i) result += nodeCount(tree, node.child[i]);
    return result;
}
void serialize(const Tree& tree, int id, std::array<std::int64_t, 81>& words, int& used) {
    const Node& node = tree.nodes[id]; words[used++] = node.kind;
    words[used++] = node.kind == Leaf ? node.arg : node.count;
    if (node.kind != Leaf) for (int i = 0; i < node.count; ++i) serialize(tree, node.child[i], words, used);
}
void storeI64(std::array<std::uint8_t, MaxOutput>& out, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) out[offset + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
} // namespace

extern "C" std::int64_t pq_tree_consecutive_ones(const std::int64_t* input, std::size_t length,
                                                   std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 2 || length > MaxInput) return -1;
    const auto nRaw = input[0], mRaw = input[1];
    if (nRaw < 2 || nRaw > MaxN || mRaw < 0 || mRaw > MaxM || length != static_cast<std::size_t>(2 + mRaw)) return -1;
    const int n = static_cast<int>(nRaw), m = static_cast<int>(mRaw);
    const std::uint64_t valid = (std::uint64_t{1} << n) - 1;
    for (int row = 0; row < m; ++row)
        if (input[2 + row] < 0 || (static_cast<std::uint64_t>(input[2 + row]) & ~valid)) return -1;

    Tree tree{}; tree.nextId = n + 1; tree.root = n;
    for (int i = 0; i < n; ++i) { tree.nodes[i].kind = Leaf; tree.nodes[i].arg = static_cast<std::uint8_t>(i); }
    tree.nodes[tree.root].kind = PNode; tree.nodes[tree.root].count = static_cast<std::uint8_t>(n);
    for (int i = 0; i < n; ++i) tree.nodes[tree.root].child[i] = static_cast<std::uint8_t>(i);
    for (int row = 0; row < m; ++row) {
        paint(tree, tree.root, static_cast<std::uint64_t>(input[2 + row]));
        if (!work(tree, tree.root)) {
            if (!output || capacity < 24) return -2;
            std::array<std::uint8_t, 24> staged{};
            for (int i = 0; i < 3; ++i) storeI64(staged, i * 8, 0);
            for (std::size_t i = 0; i < staged.size(); ++i) output[i] = staged[i];
            return 24;
        }
        tree.root = normalize(tree, tree.root);
    }
    canonicalize(tree, tree.root);
    std::array<std::int64_t, 81> words{}; int used = 0;
    words[used++] = 1; words[used++] = frontierCount(tree, tree.root); words[used++] = nodeCount(tree, tree.root);
    serialize(tree, tree.root, words, used);
    std::array<std::uint8_t, MaxOutput> staged{};
    for (int i = 0; i < used; ++i) storeI64(staged, static_cast<std::size_t>(i) * 8, words[i]);
    const auto bytes = static_cast<std::size_t>(used) * 8;
    if (!output || capacity < bytes) return -2;
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}

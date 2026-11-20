#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxText = 12;
constexpr int kMaxPattern = 8;
constexpr int kMaxSigma = 4;
constexpr int kMaxSuffixes = kMaxText + 1;
constexpr int kMaxNodes = 2 * kMaxSuffixes - 1;
constexpr std::size_t kMaxInput = 24;
constexpr std::size_t kMaxOutput = 16;

struct Node {
    int edge_start = 0;
    int edge_length = 0;
    int depth = 0;
    int leaf_start = -1;
    std::array<int, 5> child{};
    int leaf_count = 0;
    int sa_left = 0;
    int sa_right = -1;
    bool sigma = false;
    int kind = 0;  // 1 branching sigma, 2 unary sigma, 3 sigma leaf.
    int sigma_child_count = 0;
    std::array<int, 5> sigma_child{};
    std::array<int, kMaxSigma> child_by_symbol{};
    std::array<int, kMaxSigma> group_by_symbol{};
    int gap_count = 0;
    std::array<int, 5> gap_left{};
    std::array<int, 5> gap_right{};
    int separator = -1;
    int only_sigma_child = -1;
    bool left_valid = false;
    int left_interval[2] = {-1, -1};
    bool right_valid = false;
    int right_interval[2] = {-1, -1};

    Node() {
        child.fill(-1);
        sigma_child.fill(-1);
        child_by_symbol.fill(-1);
        group_by_symbol.fill(-1);
        gap_left.fill(-1);
        gap_right.fill(-1);
    }
};

int slot(int symbol) { return symbol + 1; }

int compare_suffixes(const std::array<int, kMaxSuffixes>& text,
                     int text_length, int a, int b) {
    int offset = 0;
    while (a + offset < text_length && b + offset < text_length) {
        if (text[a + offset] != text[b + offset])
            return text[a + offset] < text[b + offset] ? -1 : 1;
        ++offset;
    }
    if (a + offset == text_length && b + offset == text_length) return 0;
    return a + offset == text_length ? -1 : 1;
}

void suffix_array(const std::array<int, kMaxSuffixes>& text, int text_length,
                  std::array<int, kMaxSuffixes>& sa,
                  std::array<int, kMaxSuffixes>& rank) {
    for (int i = 0; i < text_length; ++i) sa[i] = i;
    for (int i = 1; i < text_length; ++i) {
        const int item = sa[i];
        int j = i;
        while (j > 0 && compare_suffixes(text, text_length, item, sa[j - 1]) < 0) {
            sa[j] = sa[j - 1];
            --j;
        }
        sa[j] = item;
    }
    for (int i = 0; i < text_length; ++i) rank[sa[i]] = i;
}

void insert_suffix(std::array<Node, kMaxNodes>& nodes, int& node_count,
                   const std::array<int, kMaxSuffixes>& text,
                   int text_length, int start) {
    int current = 0;
    int position = start;
    while (position < text_length) {
        const int symbol = text[position];
        int child_id = nodes[current].child[slot(symbol)];
        if (child_id < 0) {
            child_id = node_count++;
            const int length = text_length - position;
            nodes[child_id] = Node{};
            nodes[child_id].edge_start = position;
            nodes[child_id].edge_length = length;
            nodes[child_id].depth = nodes[current].depth + length;
            nodes[child_id].leaf_start = start;
            nodes[current].child[slot(symbol)] = child_id;
            return;
        }
        int common = 0;
        while (common < nodes[child_id].edge_length && position + common < text_length &&
               text[position + common] == text[nodes[child_id].edge_start + common]) ++common;
        if (common == nodes[child_id].edge_length) {
            position += common;
            current = child_id;
            continue;
        }
        const int split_id = node_count++;
        const int old_start = nodes[child_id].edge_start;
        nodes[split_id] = Node{};
        nodes[split_id].edge_start = old_start;
        nodes[split_id].edge_length = common;
        nodes[split_id].depth = nodes[current].depth + common;
        nodes[current].child[slot(symbol)] = split_id;
        nodes[child_id].edge_start += common;
        nodes[child_id].edge_length -= common;
        nodes[split_id].child[slot(text[nodes[child_id].edge_start])] = child_id;
        const int new_start = position + common;
        const int new_id = node_count++;
        nodes[new_id] = Node{};
        nodes[new_id].edge_start = new_start;
        nodes[new_id].edge_length = text_length - new_start;
        nodes[new_id].depth = nodes[split_id].depth + nodes[new_id].edge_length;
        nodes[new_id].leaf_start = start;
        nodes[split_id].child[slot(text[new_start])] = new_id;
        return;
    }
}

void summarize(std::array<Node, kMaxNodes>& nodes, int node_id,
               const std::array<int, kMaxSuffixes>& rank,
               const std::array<int, kMaxSuffixes>& text, int sigma) {
    Node& node = nodes[node_id];
    if (node.leaf_start >= 0) {
        node.leaf_count = 1;
        node.sa_left = rank[node.leaf_start];
        node.sa_right = node.sa_left;
        return;
    }
    node.leaf_count = 0;
    node.sa_left = kMaxSuffixes;
    node.sa_right = -1;
    for (int symbol = -1; symbol < sigma; ++symbol) {
        const int child = node.child[slot(symbol)];
        if (child < 0) continue;
        summarize(nodes, child, rank, text, sigma);
        node.leaf_count += nodes[child].leaf_count;
        node.sa_left = std::min(node.sa_left, nodes[child].sa_left);
        node.sa_right = std::max(node.sa_right, nodes[child].sa_right);
    }
    (void)text;
}

void interval_from_children(const std::array<Node, kMaxNodes>& nodes,
                            const int* children, int count,
                            bool& valid, int interval[2]) {
    valid = count > 0;
    if (!valid) { interval[0] = interval[1] = -1; return; }
    interval[0] = nodes[children[0]].sa_left;
    interval[1] = nodes[children[count - 1]].sa_right;
}

void build_tray(std::array<Node, kMaxNodes>& nodes, int node_count, int sigma,
                const std::array<int, kMaxSuffixes>& text) {
    for (int i = 0; i < node_count; ++i) nodes[i].sigma = nodes[i].leaf_count >= sigma;
    for (int id = 0; id < node_count; ++id) {
        Node& node = nodes[id];
        if (!node.sigma) continue;
        int children[5], child_count = 0;
        for (int symbol = -1; symbol < sigma; ++symbol) {
            const int child = node.child[slot(symbol)];
            if (child >= 0) children[child_count++] = child;
        }
        int sigma_children[5], sig_count = 0;
        for (int i = 0; i < child_count; ++i)
            if (nodes[children[i]].sigma) sigma_children[sig_count++] = children[i];
        node.sigma_child_count = sig_count;
        for (int i = 0; i < sig_count; ++i) node.sigma_child[i] = sigma_children[i];
        if (sig_count == 0) { node.kind = 3; continue; }
        if (sig_count == 1) {
            node.kind = 2;
            const int child = sigma_children[0];
            node.only_sigma_child = child;
            node.separator = text[nodes[child].edge_start];
            int left[5], right[5], left_count = 0, right_count = 0;
            bool after = false;
            for (int i = 0; i < child_count; ++i) {
                if (children[i] == child) { after = true; continue; }
                if (!nodes[children[i]].sigma) {
                    if (after) right[right_count++] = children[i];
                    else left[left_count++] = children[i];
                }
            }
            interval_from_children(nodes, left, left_count, node.left_valid, node.left_interval);
            interval_from_children(nodes, right, right_count, node.right_valid, node.right_interval);
            continue;
        }
        node.kind = 1;
        int groups[6][5]{};
        int group_sizes[6]{};
        int group = 0;
        for (int i = 0; i < child_count; ++i) {
            if (nodes[children[i]].sigma) ++group;
            else groups[group][group_sizes[group]++] = children[i];
        }
        node.gap_count = sig_count + 1;
        for (int g = 0; g <= sig_count; ++g) {
            if (group_sizes[g] > 0) {
                node.gap_left[g] = nodes[groups[g][0]].sa_left;
                node.gap_right[g] = nodes[groups[g][group_sizes[g] - 1]].sa_right;
            }
        }
        for (int symbol = 0; symbol < sigma; ++symbol) {
            int exact_child = -1;
            int before = 0;
            for (int i = 0; i < sig_count; ++i) {
                const int first = text[nodes[sigma_children[i]].edge_start];
                if (first == symbol) { exact_child = sigma_children[i]; break; }
                if (first < symbol) ++before;
            }
            if (exact_child >= 0) node.child_by_symbol[symbol] = exact_child;
            else if (group_sizes[before] > 0) node.group_by_symbol[symbol] = before;
        }
    }
}

int suffix_compare_pattern(const std::array<int, kMaxSuffixes>& text, int text_length,
                           int suffix, const int* pattern, int q, int start_at, int& lcp) {
    int i = start_at;
    while (i < q && suffix + i < text_length) {
        if (text[suffix + i] != pattern[i]) {
            lcp = i;
            return text[suffix + i] < pattern[i] ? -1 : 1;
        }
        ++i;
    }
    lcp = i;
    return i == q ? 1 : -1;
}

int interval_search(const std::array<int, kMaxSuffixes>& text, int text_length,
                    const int* pattern, int q, const std::array<int, kMaxSuffixes>& sa,
                    int lo, int hi, int known_prefix) {
    int low = lo - 1, high = hi + 1;
    int low_lcp = known_prefix, high_lcp = known_prefix;
    while (high - low > 1) {
        const int middle = (low + high) / 2;
        int lcp = known_prefix;
        const int comparison = suffix_compare_pattern(
            text, text_length, sa[middle], pattern, q,
            std::min(low_lcp, high_lcp), lcp);
        if (comparison < 0) { low = middle; low_lcp = lcp; }
        else { high = middle; high_lcp = lcp; }
    }
    if (high > hi) return -1;
    const int start = sa[high];
    if (start + q > text_length) return -1;
    for (int i = 0; i < q; ++i) if (text[start + i] != pattern[i]) return -1;
    return start;
}

int tray_query(const std::array<int, kMaxSuffixes>& text, int text_length,
               const int* pattern, int q, int sigma,
               const std::array<int, kMaxSuffixes>& sa,
               const std::array<Node, kMaxNodes>& nodes) {
    int current = 0, matched = 0;
    for (;;) {
        const Node& node = nodes[current];
        if (matched == q) return sa[node.sa_left];
        if (!node.sigma || node.kind == 3)
            return interval_search(text, text_length, pattern, q, sa,
                                   node.sa_left, node.sa_right, matched);
        const int symbol = pattern[matched];
        int next = -1, interval_left = -1, interval_right = -1;
        if (node.kind == 1) {
            next = node.child_by_symbol[symbol];
            if (next < 0) {
                const int g = node.group_by_symbol[symbol];
                if (g < 0 || node.gap_left[g] < 0) return -1;
                interval_left = node.gap_left[g];
                interval_right = node.gap_right[g];
            }
        } else {
            next = node.only_sigma_child;
            if (symbol != node.separator) {
                const int* interval = symbol < node.separator ? node.left_interval : node.right_interval;
                const bool valid = symbol < node.separator ? node.left_valid : node.right_valid;
                if (!valid) return -1;
                interval_left = interval[0];
                interval_right = interval[1];
            }
        }
        if (interval_left >= 0)
            return interval_search(text, text_length, pattern, q, sa,
                                   interval_left, interval_right, matched);
        if (next < 0) return -1;
        const Node& child = nodes[next];
        const int representative = sa[child.sa_left];
        int edge_position = node.depth;
        while (matched < q && edge_position < child.depth) {
            if (text[representative + edge_position] != pattern[matched]) return -1;
            ++matched;
            ++edge_position;
        }
        if (matched == q) return sa[child.sa_left];
        if (edge_position != child.depth) return -1;
        current = next;
    }
}

void put_i64_le(std::uint8_t* output, std::size_t position, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i)
        output[position + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}  // namespace

extern "C" std::int64_t suffix_tray_pattern_query(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > kMaxInput) return -1;
    const std::int64_t sigma64 = input[0], n64 = input[1], q64 = input[2];
    if (sigma64 < 2 || sigma64 > kMaxSigma || n64 < 1 || n64 > kMaxText ||
        q64 < 1 || q64 > kMaxPattern) return -1;
    const int sigma = static_cast<int>(sigma64), n = static_cast<int>(n64), q = static_cast<int>(q64);
    if (length != static_cast<std::size_t>(3 + n + q)) return -1;
    std::array<int, kMaxSuffixes> text{};
    std::array<int, kMaxPattern> pattern{};
    for (int i = 0; i < n; ++i) {
        if (input[3 + i] < 0 || input[3 + i] >= sigma) return -1;
        text[i] = static_cast<int>(input[3 + i]);
    }
    text[n] = -1;
    for (int i = 0; i < q; ++i) {
        if (input[3 + n + i] < 0 || input[3 + n + i] >= sigma) return -1;
        pattern[i] = static_cast<int>(input[3 + n + i]);
    }
    if (output == nullptr || capacity < kMaxOutput) return -2;

    std::array<int, kMaxSuffixes> sa{}, rank{};
    suffix_array(text, n + 1, sa, rank);
    std::array<Node, kMaxNodes> nodes{};
    int node_count = 1;
    for (int start = 0; start <= n; ++start) insert_suffix(nodes, node_count, text, n + 1, start);
    summarize(nodes, 0, rank, text, sigma);
    build_tray(nodes, node_count, sigma, text);
    const int found = tray_query(text, n + 1, pattern.data(), q, sigma, sa, nodes);
    put_i64_le(output, 0, found < 0 ? 0 : 1);
    put_i64_le(output, 8, found);
    return static_cast<std::int64_t>(kMaxOutput);
}

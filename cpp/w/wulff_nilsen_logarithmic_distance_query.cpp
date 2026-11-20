#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int K = 16;
constexpr int MaxN = 8;
constexpr int MaxM = 28;
constexpr int MaxQ = 32;
constexpr int MaxInput = 167;
constexpr int MaxTreeNodes = 31;
constexpr int LogK = 4;
constexpr std::int64_t Inf = INT64_C(0x3fffffffffffffff);

struct Split {
    int first_level = 0;
    int last_level = 0;
    int midpoint = -1;
    int gap_index = -1;
    int left_child = -1;
    int right_child = -1;
};

struct State {
    std::array<std::array<std::int64_t, MaxN>, MaxN> distance{};
    std::array<std::array<int, MaxN>, K> nearest{};
    std::array<std::array<bool, MaxN>, MaxN> bunch{};
    std::array<std::array<Split, MaxTreeNodes>, MaxN> tree{};
    std::array<int, MaxN> node_count{};
};

void write_i64_le(std::uint8_t* output, std::size_t offset,
                  std::int64_t value) noexcept {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffU);
        bits >>= 8;
    }
}

int choose_midpoint(int low, int high) noexcept {
    int chosen = -1;
    int best_distance = 0x7fffffff;
    for (int candidate = low + 2; candidate <= high - 2; candidate += 2) {
        const int delta = 2 * candidate - low - high;
        const int absolute = delta < 0 ? -delta : delta;
        if (absolute < best_distance) {
            best_distance = absolute;
            chosen = candidate;
        }
    }
    return chosen;
}

int make_interval_tree(State& state, int source, int low, int high) noexcept {
    int& used = state.node_count[static_cast<std::size_t>(source)];
    if (used >= MaxTreeNodes) return -1;
    const int node_id = used++;
    Split& node = state.tree[static_cast<std::size_t>(source)][static_cast<std::size_t>(node_id)];
    node.first_level = low;
    node.last_level = high;
    if (high - low <= LogK) return node_id;

    const int middle = choose_midpoint(low, high);
    if (middle < 0) return -1;
    int selected_gap = low;
    auto gap_value = [&](int index) {
        const int farther = state.nearest[static_cast<std::size_t>(index + 2)][static_cast<std::size_t>(source)];
        const int nearer = state.nearest[static_cast<std::size_t>(index)][static_cast<std::size_t>(source)];
        return state.distance[static_cast<std::size_t>(source)][static_cast<std::size_t>(farther)]
             - state.distance[static_cast<std::size_t>(source)][static_cast<std::size_t>(nearer)];
    };
    auto best_gap = gap_value(low);
    for (int index = low + 2; index <= middle - 2; index += 2) {
        const auto value = gap_value(index);
        if (value > best_gap) {
            selected_gap = index;
            best_gap = value;
        }
    }
    node.midpoint = middle;
    node.gap_index = selected_gap;
    const int left = make_interval_tree(state, source, low, selected_gap);
    const int right = make_interval_tree(state, source, middle, high);
    if (left < 0 || right < 0) return -1;
    node.left_child = left;
    node.right_child = right;
    return node_id;
}

bool run_dist_k(const State& state, int n, int source, int target, int start,
                std::int64_t& estimate, int& probes) noexcept {
    int level = start;
    while (level < K) {
        const int pivot = state.nearest[static_cast<std::size_t>(level)][static_cast<std::size_t>(source)];
        ++probes;
        if (state.bunch[static_cast<std::size_t>(target)][static_cast<std::size_t>(pivot)]) {
            estimate = state.distance[static_cast<std::size_t>(source)][static_cast<std::size_t>(pivot)]
                     + state.distance[static_cast<std::size_t>(target)][static_cast<std::size_t>(pivot)];
            return true;
        }
        if (level + 1 == K) return false;
        const int temporary = source;
        source = target;
        target = temporary;
        ++level;
        if (source < 0 || source >= n) return false;
    }
    return false;
}
} // namespace

extern "C" std::int64_t wulff_nilsen_logarithmic_distance_query(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 18 || length > MaxInput) return -1;
    const auto n_value = input[0];
    const auto m_value = input[1];
    if (n_value < 1 || n_value > MaxN || m_value < 0 || m_value > MaxM) return -1;
    const int n = static_cast<int>(n_value);
    const int m = static_cast<int>(m_value);

    std::array<std::uint64_t, K> layers{};
    const auto vertex_bits = (std::uint64_t{1} << static_cast<unsigned>(n)) - 1U;
    for (int level = 1; level < K; ++level) {
        const auto raw = input[static_cast<std::size_t>(1 + level)];
        if (raw <= 0 || (static_cast<std::uint64_t>(raw) & ~vertex_bits) != 0) return -1;
        layers[static_cast<std::size_t>(level)] = static_cast<std::uint64_t>(raw);
        if (level > 1 && (layers[static_cast<std::size_t>(level)]
                & ~layers[static_cast<std::size_t>(level - 1)]) != 0) return -1;
    }

    const std::size_t query_at = 17U + 3U * static_cast<std::size_t>(m);
    if (query_at >= length) return -1;
    const auto q_value = input[query_at];
    if (q_value < 0 || q_value > MaxQ
            || length != query_at + 1U + 2U * static_cast<std::size_t>(q_value)) return -1;
    const int q = static_cast<int>(q_value);

    State state{};
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            state.distance[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] = (i == j) ? 0 : Inf;

    int previous_u = -1, previous_v = -1;
    for (int edge = 0; edge < m; ++edge) {
        const auto offset = static_cast<std::size_t>(17 + 3 * edge);
        const auto u_raw = input[offset];
        const auto v_raw = input[offset + 1];
        const auto weight = input[offset + 2];
        if (u_raw < 0 || v_raw <= u_raw || v_raw >= n || weight < 1 || weight > 1000) return -1;
        const int u = static_cast<int>(u_raw), v = static_cast<int>(v_raw);
        if (u < previous_u || (u == previous_u && v <= previous_v)) return -1;
        previous_u = u; previous_v = v;
        state.distance[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] = weight;
        state.distance[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)] = weight;
    }
    for (int via = 0; via < n; ++via)
        for (int from = 0; from < n; ++from)
            for (int to = 0; to < n; ++to) {
                const auto candidate = state.distance[static_cast<std::size_t>(from)][static_cast<std::size_t>(via)]
                                     + state.distance[static_cast<std::size_t>(via)][static_cast<std::size_t>(to)];
                if (candidate < state.distance[static_cast<std::size_t>(from)][static_cast<std::size_t>(to)])
                    state.distance[static_cast<std::size_t>(from)][static_cast<std::size_t>(to)] = candidate;
            }
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            if (state.distance[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] == Inf) return -1;

    for (int vertex = 0; vertex < n; ++vertex)
        state.nearest[0][static_cast<std::size_t>(vertex)] = vertex;
    for (int level = 1; level < K; ++level) {
        for (int vertex = 0; vertex < n; ++vertex) {
            int best = -1;
            for (int candidate = 0; candidate < n; ++candidate) {
                if (((layers[static_cast<std::size_t>(level)] >> static_cast<unsigned>(candidate)) & 1U) == 0) continue;
                if (best < 0 || state.distance[static_cast<std::size_t>(vertex)][static_cast<std::size_t>(candidate)]
                                    < state.distance[static_cast<std::size_t>(vertex)][static_cast<std::size_t>(best)]
                    || (state.distance[static_cast<std::size_t>(vertex)][static_cast<std::size_t>(candidate)]
                                    == state.distance[static_cast<std::size_t>(vertex)][static_cast<std::size_t>(best)]
                        && candidate < best)) best = candidate;
            }
            if (best < 0) return -1;
            state.nearest[static_cast<std::size_t>(level)][static_cast<std::size_t>(vertex)] = best;
        }
    }

    for (int center = 0; center < n; ++center) {
        for (int level = 0; level < K; ++level) {
            const auto current = level == 0 ? vertex_bits : layers[static_cast<std::size_t>(level)];
            const auto next = level + 1 == K ? 0U : layers[static_cast<std::size_t>(level + 1)];
            std::int64_t threshold = Inf;
            for (int candidate = 0; candidate < n; ++candidate)
                if (((next >> static_cast<unsigned>(candidate)) & 1U) != 0
                        && state.distance[static_cast<std::size_t>(center)][static_cast<std::size_t>(candidate)] < threshold)
                    threshold = state.distance[static_cast<std::size_t>(center)][static_cast<std::size_t>(candidate)];
            for (int candidate = 0; candidate < n; ++candidate) {
                const bool in_current = ((current >> static_cast<unsigned>(candidate)) & 1U) != 0;
                const bool in_next = ((next >> static_cast<unsigned>(candidate)) & 1U) != 0;
                if (in_current && !in_next
                        && state.distance[static_cast<std::size_t>(center)][static_cast<std::size_t>(candidate)] < threshold)
                    state.bunch[static_cast<std::size_t>(center)][static_cast<std::size_t>(candidate)] = true;
            }
        }
    }
    for (int source = 0; source < n; ++source)
        if (make_interval_tree(state, source, 0, K - 1) < 0) return -1;

    std::array<std::int64_t, 1 + 2 * MaxQ> staged{};
    staged[0] = q;
    for (int query = 0; query < q; ++query) {
        const auto offset = query_at + 1U + 2U * static_cast<std::size_t>(query);
        const auto source_raw = input[offset], target_raw = input[offset + 1];
        if (source_raw < 0 || source_raw >= n || target_raw < 0 || target_raw >= n) return -1;
        const int source = static_cast<int>(source_raw), target = static_cast<int>(target_raw);
        if (source == target) {
            staged[static_cast<std::size_t>(1 + 2 * query)] = 0;
            staged[static_cast<std::size_t>(2 + 2 * query)] = 0;
            continue;
        }
        int node_id = 0, probes = 0;
        while (state.tree[static_cast<std::size_t>(source)][static_cast<std::size_t>(node_id)].last_level
               - state.tree[static_cast<std::size_t>(source)][static_cast<std::size_t>(node_id)].first_level > LogK) {
            const auto& node = state.tree[static_cast<std::size_t>(source)][static_cast<std::size_t>(node_id)];
            const bool first = state.bunch[static_cast<std::size_t>(target)]
                [static_cast<std::size_t>(state.nearest[static_cast<std::size_t>(node.gap_index)][static_cast<std::size_t>(source)])];
            const bool second = state.bunch[static_cast<std::size_t>(source)]
                [static_cast<std::size_t>(state.nearest[static_cast<std::size_t>(node.gap_index + 1)][static_cast<std::size_t>(target)])];
            probes += 2;
            node_id = (!first && !second) ? node.right_child : node.left_child;
        }
        std::int64_t estimate = 0;
        const int start = state.tree[static_cast<std::size_t>(source)][static_cast<std::size_t>(node_id)].first_level;
        if (!run_dist_k(state, n, source, target, start, estimate, probes)) return -1;
        staged[static_cast<std::size_t>(1 + 2 * query)] = estimate;
        staged[static_cast<std::size_t>(2 + 2 * query)] = probes;
    }

    const std::size_t words = static_cast<std::size_t>(1 + 2 * q);
    const std::size_t bytes = 8U * words;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t index = 0; index < words; ++index)
        write_i64_le(output, 8U * index, staged[index]);
    return static_cast<std::int64_t>(bytes);
}

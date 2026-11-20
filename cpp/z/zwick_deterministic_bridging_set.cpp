#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 8;
constexpr int max_input = 131;
constexpr int inf_dist = 9;

struct State {
    int n = 0;
    int threshold = 0;
    std::array<std::uint8_t, 64> edge{};
    std::array<std::uint8_t, 64> witness{};
    std::array<std::uint8_t, 64> distance{};
    std::array<std::uint16_t, 64> constraints{};
    int constraint_count = 0;
};

int population(std::uint16_t mask) {
    int count = 0;
    while (mask != 0) { count += mask & 1u; mask >>= 1; }
    return count;
}

int collect_prefix(const State& state, int from, int to, int limit,
                   std::array<std::uint8_t, max_n>& output, int offset) {
    if (limit <= 0 || state.witness[from * state.n + to] == 0) return 0;
    const int middle = static_cast<int>(state.witness[from * state.n + to]) - 1;
    int count = collect_prefix(state, from, middle, limit - 1, output, offset);
    output[offset + count++] = static_cast<std::uint8_t>(middle);
    const int remaining = limit - count;
    if (remaining > 0)
        count += collect_prefix(state, middle, to, remaining, output, offset + count);
    return count;
}

bool decode(State& state, const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || length > max_input) return false;
    if (input[0] < 2 || input[0] > max_n) return false;
    const int n = static_cast<int>(input[0]);
    if (input[1] < 2 || input[1] > n || length != static_cast<std::size_t>(2 + 2*n*n))
        return false;
    state.n = n;
    state.threshold = static_cast<int>(input[1]);
    const std::size_t matrix_size = static_cast<std::size_t>(n*n);
    for (std::size_t i = 0; i < matrix_size; ++i) {
        if (input[2+i] < 0 || input[2+i] > 1 || input[2+matrix_size+i] < 0 || input[2+matrix_size+i] > n)
            return false;
        state.edge[i] = static_cast<std::uint8_t>(input[2+i]);
        state.witness[i] = static_cast<std::uint8_t>(input[2+matrix_size+i]);
    }
    for (int i=0; i<n; ++i) if (state.edge[i*n+i] != 0) return false;
    for (int i=0; i<n; ++i) for (int j=0; j<n; ++j)
        state.distance[i*n+j] = static_cast<std::uint8_t>(i==j ? 0 : (state.edge[i*n+j] ? 1 : inf_dist));
    for (int k=0; k<n; ++k) for (int i=0; i<n; ++i) for (int j=0; j<n; ++j) {
        const int candidate = state.distance[i*n+k] + state.distance[k*n+j];
        if (candidate < state.distance[i*n+j]) state.distance[i*n+j] = static_cast<std::uint8_t>(candidate);
    }
    for (int i=0; i<n; ++i) for (int j=0; j<n; ++j) {
        const int d = state.distance[i*n+j], w = state.witness[i*n+j];
        if (d >= inf_dist) return false;
        if (d <= 1) { if (w != 0) return false; }
        else {
            if (w == 0) return false;
            const int v = w-1;
            if (v==i || v==j) return false;
            const int left = state.distance[i*n+v], right = state.distance[v*n+j];
            if (left+right != d || left >= d || right >= d) return false;
        }
    }
    return true;
}
}

extern "C" std::int64_t zwick_deterministic_bridging_set(const std::int64_t* input,
                                                          std::size_t length) {
    State state{};
    if (!decode(state, input, length)) return -1;
    for (int i=0; i<state.n; ++i) for (int j=0; j<state.n; ++j) {
        std::array<std::uint8_t, max_n> prefix{};
        const int count = collect_prefix(state, i, j, state.threshold, prefix, 0);
        std::uint16_t mask = static_cast<std::uint16_t>((1u<<i) | (1u<<j));
        for (int k=0; k<count; ++k) mask |= static_cast<std::uint16_t>(1u<<prefix[k]);
        if (population(mask) >= state.threshold) {
            bool duplicate = false;
            for (int c=0; c<state.constraint_count; ++c)
                if (state.constraints[c] == mask) { duplicate=true; break; }
            if (!duplicate) state.constraints[state.constraint_count++] = mask;
        }
    }
    std::array<bool,64> remaining{};
    int left = state.constraint_count;
    for (int i=0; i<left; ++i) remaining[i] = true;
    std::uint16_t chosen = 0;
    while (left > 0) {
        int best = -1, best_score = -1;
        for (int v=0; v<state.n; ++v) {
            int score=0;
            for (int c=0; c<state.constraint_count; ++c)
                if (remaining[c] && (state.constraints[c] & (1u<<v))) ++score;
            if (score > best_score) { best=v; best_score=score; }
        }
        if (best < 0 || best_score == 0) return -1;
        chosen |= static_cast<std::uint16_t>(1u<<best);
        for (int c=0; c<state.constraint_count; ++c)
            if (remaining[c] && (state.constraints[c] & (1u<<best))) { remaining[c]=false; --left; }
    }
    return chosen;
}

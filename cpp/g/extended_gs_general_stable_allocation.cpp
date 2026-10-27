/* Bounded Extended-GS for concave multi-unit stable allocations. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_EDGES = 4;
constexpr std::size_t MAX_INPUT = 19;
constexpr std::size_t MAX_OUTPUT_BYTES = 104;
constexpr std::int64_t INF = 255;

std::int64_t utility(std::int64_t first, std::int64_t second, std::int64_t count) {
    return count == 0 ? 0 : first + (count == 2 ? second : 0);
}

void choose_men(std::size_t men, std::size_t women, std::int64_t quota, std::size_t edges,
                const std::int64_t *mf, const std::int64_t *ms,
                const std::int64_t *lower, const std::int64_t *upper,
                std::int64_t *answer) {
    std::int64_t best_value = -1;
    std::size_t codes = 1;
    for (std::size_t e = 0; e < edges; ++e) codes *= 3;
    for (std::size_t code = 0; code < codes; ++code) {
        std::size_t rem = code;
        std::int64_t candidate[MAX_EDGES]{};
        for (std::size_t e = edges; e-- > 0;) { candidate[e] = static_cast<std::int64_t>(rem % 3); rem /= 3; }
        bool feasible = true;
        for (std::size_t e = 0; e < edges; ++e)
            if (candidate[e] < lower[e] || candidate[e] > upper[e]) feasible = false;
        for (std::size_t i = 0; i < men; ++i) {
            std::int64_t total = 0;
            for (std::size_t j = 0; j < women; ++j) total += candidate[i * women + j];
            if (total > quota) feasible = false;
        }
        if (!feasible) continue;
        std::int64_t value = 0;
        for (std::size_t e = 0; e < edges; ++e) value += utility(mf[e], ms[e], candidate[e]);
        if (value > best_value) { best_value = value; for (std::size_t e = 0; e < edges; ++e) answer[e] = candidate[e]; }
    }
}

void choose_women(std::size_t men, std::size_t women, std::int64_t quota, std::size_t edges,
                  const std::int64_t *wf, const std::int64_t *ws,
                  const std::int64_t *upper, std::int64_t *answer) {
    std::int64_t best_value = -1;
    std::size_t codes = 1;
    for (std::size_t e = 0; e < edges; ++e) codes *= 3;
    for (std::size_t code = 0; code < codes; ++code) {
        std::size_t rem = code;
        std::int64_t candidate[MAX_EDGES]{};
        for (std::size_t e = edges; e-- > 0;) { candidate[e] = static_cast<std::int64_t>(rem % 3); rem /= 3; }
        bool feasible = true;
        for (std::size_t e = 0; e < edges; ++e) if (candidate[e] > upper[e]) feasible = false;
        for (std::size_t j = 0; j < women; ++j) {
            std::int64_t total = 0;
            for (std::size_t i = 0; i < men; ++i) total += candidate[i * women + j];
            if (total > quota) feasible = false;
        }
        if (!feasible) continue;
        std::int64_t value = 0;
        for (std::size_t e = 0; e < edges; ++e) value += utility(wf[e], ws[e], candidate[e]);
        if (value > best_value) { best_value = value; for (std::size_t e = 0; e < edges; ++e) answer[e] = candidate[e]; }
    }
}

void put_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t extended_gs_general_stable_allocation(const std::int64_t *input,
                                                                std::size_t length,
                                                                std::uint8_t *output,
                                                                std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > 2 || input[1] < 1 || input[1] > 2 || input[2] < 1 || input[2] > 2) return -1;
    const std::size_t men = static_cast<std::size_t>(input[0]), women = static_cast<std::size_t>(input[1]);
    const std::int64_t quota = input[2];
    const std::size_t edges = men * women;
    if (length != 3 + 4 * edges) return -1;
    std::int64_t mf[MAX_EDGES], ms[MAX_EDGES], wf[MAX_EDGES], ws[MAX_EDGES];
    for (std::size_t e = 0; e < edges; ++e) {
        mf[e] = input[3 + 4 * e]; ms[e] = input[4 + 4 * e];
        wf[e] = input[5 + 4 * e]; ws[e] = input[6 + 4 * e];
        if (mf[e] < 0 || mf[e] > 8 || ms[e] < 0 || ms[e] > mf[e] ||
            wf[e] < 0 || wf[e] > 8 || ws[e] < 0 || ws[e] > wf[e]) return -1;
    }
    std::int64_t x_w[MAX_EDGES]{}, z_m[MAX_EDGES], z_w[MAX_EDGES]{}, x_m[MAX_EDGES]{}, next_w[MAX_EDGES]{};
    for (std::size_t e = 0; e < edges; ++e) z_m[e] = INF;
    bool converged = false;
    for (std::size_t iteration = 0; iteration < 3 * edges + 2; ++iteration) {
        choose_men(men, women, quota, edges, mf, ms, x_w, z_m, x_m);
        choose_women(men, women, quota, edges, wf, ws, x_m, next_w);
        converged = true;
        for (std::size_t e = 0; e < edges; ++e) if (x_m[e] != next_w[e]) converged = false;
        if (converged) break;
        for (std::size_t e = 0; e < edges; ++e) {
            if (x_m[e] > next_w[e]) { z_m[e] = next_w[e]; z_w[e] = INF; }
            x_w[e] = next_w[e];
        }
    }
    if (!converged) return -1;
    const std::size_t output_values = 1 + 3 * edges, output_bytes = 8 * output_values;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::uint8_t staged[MAX_OUTPUT_BYTES]{};
    put_i64(staged, 0, static_cast<std::int64_t>(edges));
    for (std::size_t e = 0; e < edges; ++e) {
        put_i64(staged, 8 * (1 + e), x_m[e]);
        put_i64(staged, 8 * (1 + edges + e), z_m[e]);
        put_i64(staged, 8 * (1 + 2 * edges + e), z_w[e] > x_m[e] ? z_w[e] : x_m[e]);
    }
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(output_bytes);
}

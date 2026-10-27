#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_M = 6, MAX_W = 6, MAX_INPUT = 74, MAX_OUTPUT = 48, MAX_STEPS = 121;
void put64(std::uint8_t* output, std::size_t position, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[position + byte] = static_cast<std::uint8_t>(bits >> (8U * byte));
}
bool man_prefers(std::size_t man, std::size_t a, std::size_t b,
    const std::int64_t rank[MAX_M][MAX_W], const std::int64_t woman_partner[MAX_W]) {
    if (rank[man][a] != rank[man][b]) return rank[man][a] < rank[man][b];
    bool a_maiden = woman_partner[a] == -1, b_maiden = woman_partner[b] == -1;
    return a_maiden != b_maiden ? a_maiden : a < b;
}
bool uncertain(std::size_t man, std::size_t w, const std::int64_t rank[MAX_M][MAX_W],
    const bool live[MAX_M][MAX_W], const std::int64_t assignment[MAX_M],
    const std::int64_t woman_partner[MAX_W], const int status[MAX_M]) {
    if (status[man] != 0 || assignment[man] < 0) return false;
    auto fiance = static_cast<std::size_t>(assignment[man]);
    for (std::size_t woman = 0; woman < w; ++woman)
        if (live[man][woman] && woman != fiance &&
            (rank[man][woman] < rank[man][fiance] ||
             (rank[man][woman] == rank[man][fiance] && woman_partner[woman] == -1 && woman_partner[fiance] != -1))) return true;
    return false;
}
bool woman_prefers(std::size_t woman, std::size_t candidate, std::size_t incumbent,
    bool incumbent_uncertain, const std::int64_t rank[MAX_W][MAX_M], const int status[MAX_M]) {
    if (incumbent_uncertain) return true;
    if (rank[woman][candidate] != rank[woman][incumbent]) return rank[woman][candidate] < rank[woman][incumbent];
    return status[candidate] != status[incumbent] ? status[candidate] > status[incumbent] : candidate < incumbent;
}
}

extern "C" std::int64_t kiraly_max_smt_i_approx(const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > MAX_INPUT) return -1;
    auto m64 = input[0], w64 = input[1];
    if (m64 < 1 || m64 > MAX_M || w64 < 1 || w64 > MAX_W) return -1;
    auto m = static_cast<std::size_t>(m64), w = static_cast<std::size_t>(w64);
    if (length != 2 + 2*m*w) return -1;
    std::int64_t men_rank[MAX_M][MAX_W]{}, women_rank[MAX_W][MAX_M]{};
    bool live[MAX_M][MAX_W]{};
    std::int64_t assignment[MAX_M], woman_partner[MAX_W];
    int status[MAX_M]{}; // lad, bachelor, old bachelor
    for (std::size_t man = 0; man < m; ++man) {
        assignment[man] = -1;
        for (std::size_t woman = 0; woman < w; ++woman) {
            auto rank = input[2 + man*w + woman];
            if (rank < -1 || rank >= MAX_W) return -1;
            men_rank[man][woman] = rank;
        }
    }
    for (std::size_t woman = 0; woman < w; ++woman) {
        woman_partner[woman] = -1;
        for (std::size_t man = 0; man < m; ++man) {
            auto rank = input[2 + m*w + woman*m + man];
            if (rank < -1 || rank >= MAX_M) return -1;
            women_rank[woman][man] = rank;
        }
    }
    for (std::size_t man = 0; man < m; ++man)
        for (std::size_t woman = 0; woman < w; ++woman) {
            bool ma = men_rank[man][woman] >= 0, wa = women_rank[woman][man] >= 0;
            if (ma != wa) return -1;
            live[man][woman] = ma;
        }
    auto output_bytes = 8*m;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::size_t steps = 0;
    while (true) {
        if (++steps > MAX_STEPS) return -1;
        std::size_t man = m;
        for (std::size_t x = 0; x < m; ++x) if (status[x] != 2 && assignment[x] == -1) { man = x; break; }
        if (man == m) break;
        std::size_t woman = w;
        for (std::size_t x = 0; x < w; ++x)
            if (live[man][x] && (woman == w || man_prefers(man, x, woman, men_rank, woman_partner))) woman = x;
        if (woman == w) {
            if (status[man] == 0) {
                status[man] = 1;
                for (std::size_t x = 0; x < w; ++x) live[man][x] = men_rank[man][x] >= 0;
            } else status[man] = 2;
            continue;
        }
        auto incumbent64 = woman_partner[woman];
        if (incumbent64 < 0) {
            assignment[man] = static_cast<std::int64_t>(woman); woman_partner[woman] = static_cast<std::int64_t>(man); continue;
        }
        auto incumbent = static_cast<std::size_t>(incumbent64);
        bool old_uncertain = uncertain(incumbent, w, men_rank, live, assignment, woman_partner, status);
        if (woman_prefers(woman, man, incumbent, old_uncertain, women_rank, status)) {
            assignment[incumbent] = -1; woman_partner[woman] = -1;
            if (!old_uncertain) live[incumbent][woman] = false;
            assignment[man] = static_cast<std::int64_t>(woman); woman_partner[woman] = static_cast<std::int64_t>(man);
        } else live[man][woman] = false;
    }
    std::uint8_t staged[MAX_OUTPUT]{};
    for (std::size_t man = 0; man < m; ++man) put64(staged, 8*man, assignment[man]);
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(output_bytes);
}

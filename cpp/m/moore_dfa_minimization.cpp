#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_states = 8;
constexpr std::size_t max_alphabet = 3;
}

extern "C" std::int64_t moore_dfa_minimization(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 4 || length > 29) return -1;
    const auto n64 = input[0], alphabet64 = input[1], start64 = input[2], accepting = input[3];
    if (n64 < 1 || n64 > 8 || alphabet64 < 1 || alphabet64 > 3
        || start64 < 0 || start64 >= n64 || accepting < 0 || accepting >= (std::int64_t{1} << n64)) return -1;
    const auto n = static_cast<std::size_t>(n64), alphabet = static_cast<std::size_t>(alphabet64);
    if (length != 4 + n * alphabet) return -1;
    std::array<std::array<int, max_alphabet>, max_states> transition{};
    for (std::size_t s = 0; s < n; ++s) for (std::size_t a = 0; a < alphabet; ++a) {
        const auto target = input[4 + s * alphabet + a];
        if (target < 0 || target >= n64) return -1;
        transition[s][a] = static_cast<int>(target);
    }
    std::array<int, max_states> labels{}, refined{};
    std::array<int, 2> acceptance_id{-1, -1};
    int classes = 0;
    for (std::size_t s = 0; s < n; ++s) {
        const int bit = static_cast<int>((accepting >> s) & 1);
        if (acceptance_id[bit] < 0) acceptance_id[bit] = classes++;
        labels[s] = acceptance_id[bit];
    }
    int rounds = 0;
    for (;;) {
        std::array<int, max_states> signatures{};
        int signature_count = 0;
        for (std::size_t s = 0; s < n; ++s) {
            int signature = labels[s];
            for (std::size_t a = 0; a < alphabet; ++a)
                signature = signature * 8 + labels[static_cast<std::size_t>(transition[s][a])];
            int id = 0;
            while (id < signature_count && signatures[id] != signature) ++id;
            if (id == signature_count) signatures[signature_count++] = signature;
            refined[s] = id;
        }
        bool changed = false;
        for (std::size_t s = 0; s < n; ++s) changed |= refined[s] != labels[s];
        if (!changed) { classes = signature_count; break; }
        for (std::size_t s = 0; s < n; ++s) labels[s] = refined[s];
        classes = signature_count;
        ++rounds;
    }
    std::int64_t packed = (std::int64_t{classes} << 28) | (std::int64_t{rounds} << 24);
    for (std::size_t s = 0; s < n; ++s) packed |= std::int64_t{labels[s]} << (3 * s);
    return packed;
}

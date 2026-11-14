// Unverified deterministic planted 3-SAT generator draft.
#include <cstddef>
#include <cstdint>
#include <vector>

extern "C" std::int64_t planted_3sat_clause_generator(const std::int64_t* input, std::size_t length,
                                                       std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 5 || length > 83 || input[0] < 3 || input[0] > 16 || input[1] < 0 || input[1] > 32) return -1;
    const auto n = static_cast<std::size_t>(input[0]), m = static_cast<std::size_t>(input[1]);
    if (length != 2+n+2*m) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[2+i] != 0 && input[2+i] != 1) return -1;
    const auto choices = n*(n-1)*(n-2)/6;
    std::vector<std::int64_t> literals;
    literals.reserve(3*m);
    for (std::size_t clause = 0; clause < m; ++clause) {
        const auto raw = input[2+n+2*clause], mask = input[3+n+2*clause];
        if (raw < 0 || static_cast<std::uint64_t>(raw) >= choices || mask < 1 || mask > 7) return -1;
        auto rank = static_cast<std::size_t>(raw);
        std::size_t next = 0;
        for (std::size_t position = 0; position < 3; ++position) {
            for (auto variable = next; variable < n-(2-position); ++variable) {
                const auto remaining = n-variable-1;
                const auto ways = position == 0 ? remaining*(remaining-1)/2 : position == 1 ? remaining : 1;
                if (rank >= ways) { rank -= ways; continue; }
                const auto value = static_cast<std::int64_t>(variable+1);
                literals.push_back(input[2+variable] == ((mask >> position) & 1) ? value : -value);
                next = variable+1; break;
            }
        }
    }
    const auto bytes = 24*m;
    if (bytes && (!output || capacity < bytes)) return -2;
    for (std::size_t i = 0; i < literals.size(); ++i) {
        const auto bits = static_cast<std::uint64_t>(literals[i]);
        for (std::size_t b = 0; b < 8; ++b) output[8*i+b] = static_cast<std::uint8_t>(bits >> (8*b));
    }
    return static_cast<std::int64_t>(bytes);
}

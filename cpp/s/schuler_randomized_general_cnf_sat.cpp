#include <cstddef>
#include <cstdint>
#include <cstdlib>

namespace {
constexpr int max_n = 6;
constexpr int max_m = 4;
constexpr int max_calls = max_n + 1;
constexpr std::size_t max_input = 122;

struct Stats { int calls, unit_forces, random_guesses, max_depth; };

int prefix_size(int clauses) {
    int bits = 0;
    while (clauses > 0) { ++bits; clauses >>= 1; }
    return bits + 1;
}

bool ppz(int n, int m, int formula[max_m][max_n], int lengths[max_m],
         const int fixed[max_n], const int permutation[max_n], const int bits[max_n],
         int local[max_n], Stats &stats) {
    int active[max_n]{}, active_count = 0;
    for (int variable = 0; variable < n; ++variable) local[variable] = -1;
    for (int position = 0; position < n; ++position) {
        const int variable = permutation[position] - 1;
        if (fixed[variable] < 0) active[active_count++] = variable;
    }

    int work[max_m][max_n]{};
    int work_lengths[max_m]{};
    for (int clause = 0; clause < m; ++clause) {
        work_lengths[clause] = lengths[clause];
        for (int item = 0; item < lengths[clause]; ++item)
            work[clause][item] = formula[clause][item];
    }
    for (int offset = 0; offset < active_count; ++offset) {
        const int variable = active[offset];
        bool positive_unit = false, negative_unit = false;
        for (int clause = 0; clause < m; ++clause) {
            if (work_lengths[clause] != 1) continue;
            positive_unit |= work[clause][0] == variable + 1;
            negative_unit |= work[clause][0] == -(variable + 1);
        }
        int value;
        if (positive_unit) { value = 1; ++stats.unit_forces; }
        else if (negative_unit) { value = 0; ++stats.unit_forces; }
        else { value = bits[offset]; ++stats.random_guesses; }
        local[variable] = value;

        int next[max_m][max_n]{};
        int next_lengths[max_m]{};
        int next_m = 0;
        for (int clause = 0; clause < m; ++clause) {
            bool satisfied = false;
            int out_length = 0;
            for (int item = 0; item < work_lengths[clause]; ++item) {
                const int literal = work[clause][item];
                if (std::abs(literal) - 1 != variable) next[next_m][out_length++] = literal;
                else if ((literal > 0) == (value != 0)) { satisfied = true; break; }
            }
            if (!satisfied) next_lengths[next_m++] = out_length;
        }
        for (int clause = 0; clause < next_m; ++clause) {
            work_lengths[clause] = next_lengths[clause];
            for (int item = 0; item < next_lengths[clause]; ++item)
                work[clause][item] = next[clause][item];
        }
        m = next_m;
    }
    for (int clause = 0; clause < m; ++clause)
        if (work_lengths[clause] == 0) return false;
    return true;
}

void put_i64(std::uint8_t *output, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[8 * word + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t schuler_randomized_general_cnf_sat(
        const std::int64_t *input, std::size_t length,
        std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > max_n || m0 < 1 || m0 > max_m) return -1;
    const int n = static_cast<int>(n0), original_m = static_cast<int>(m0);
    int formula[max_m][max_n]{};
    int lengths[max_m]{};
    std::size_t position = 2;
    for (int clause = 0; clause < original_m; ++clause) {
        if (position >= length) return -1;
        const auto count0 = input[position++];
        if (count0 < 1 || count0 > n || position + static_cast<std::size_t>(count0) > length) return -1;
        bool seen[max_n]{};
        lengths[clause] = static_cast<int>(count0);
        for (int item = 0; item < lengths[clause]; ++item) {
            const auto literal0 = input[position++];
            if (literal0 == 0 || literal0 < -n || literal0 > n) return -1;
            const int variable = static_cast<int>(std::abs(literal0)) - 1;
            if (seen[variable]) return -1;
            seen[variable] = true;
            formula[clause][item] = static_cast<int>(literal0);
        }
    }

    int permutations[max_calls][max_n]{};
    int random_bits[max_calls][max_n]{};
    int choices[max_calls]{};
    for (int call = 0; call <= n; ++call) {
        bool seen[max_n]{};
        for (int item = 0; item < n; ++item) {
            if (position >= length) return -1;
            const auto value = input[position++];
            if (value < 1 || value > n || seen[static_cast<int>(value) - 1]) return -1;
            seen[static_cast<int>(value) - 1] = true;
            permutations[call][item] = static_cast<int>(value);
        }
        for (int item = 0; item < n; ++item) {
            if (position >= length || (input[position] != 0 && input[position] != 1)) return -1;
            random_bits[call][item] = static_cast<int>(input[position++]);
        }
        if (position >= length) return -1;
        const auto choice = input[position++];
        if (choice < 0 || choice >= m0) return -1;
        choices[call] = static_cast<int>(choice);
    }
    if (position != length) return -1;

    int fixed[max_n];
    for (int variable = 0; variable < n; ++variable) fixed[variable] = -1;
    int current[max_m][max_n]{};
    int current_lengths[max_m]{};
    int current_m = original_m;
    for (int clause = 0; clause < current_m; ++clause) {
        current_lengths[clause] = lengths[clause];
        for (int item = 0; item < lengths[clause]; ++item)
            current[clause][item] = formula[clause][item];
    }
    Stats stats{0, 0, 0, 0};
    int found = 0, mask = 0, depth = 0;
    while (true) {
        ++stats.calls;
        if (depth > stats.max_depth) stats.max_depth = depth;
        if (current_m == 0) {
            found = 1;
            for (int variable = 0; variable < n; ++variable)
                if (fixed[variable] == 1) mask |= 1 << variable;
            break;
        }
        const int k = prefix_size(current_m);
        int shortened[max_m][max_n]{};
        int short_lengths[max_m]{};
        for (int clause = 0; clause < current_m; ++clause) {
            short_lengths[clause] = current_lengths[clause] < k ? current_lengths[clause] : k;
            for (int item = 0; item < short_lengths[clause]; ++item)
                shortened[clause][item] = current[clause][item];
        }
        int local[max_n];
        for (int variable = 0; variable < n; ++variable) local[variable] = -1;
        if (ppz(n, current_m, shortened, short_lengths, fixed,
               permutations[depth], random_bits[depth], local, stats)) {
            found = 1;
            for (int variable = 0; variable < n; ++variable) {
                const int value = fixed[variable] >= 0 ? fixed[variable] : local[variable];
                if (value == 1) mask |= 1 << variable;
            }
            break;
        }
        int eligible[max_m], eligible_count = 0;
        for (int clause = 0; clause < current_m; ++clause)
            if (short_lengths[clause] == k) eligible[eligible_count++] = clause;
        if (eligible_count == 0) break;
        if (choices[depth] >= eligible_count) return -1;
        const int selected = eligible[choices[depth]];
        int next_fixed[max_n];
        for (int variable = 0; variable < n; ++variable) next_fixed[variable] = fixed[variable];
        for (int item = 0; item < k; ++item) {
            const int literal = shortened[selected][item];
            next_fixed[std::abs(literal) - 1] = literal > 0 ? 0 : 1;
        }
        int next[max_m][max_n]{};
        int next_lengths[max_m]{};
        int next_m = 0;
        for (int clause = 0; clause < current_m; ++clause) {
            bool satisfied = false;
            int out_length = 0;
            for (int item = 0; item < current_lengths[clause]; ++item) {
                const int literal = current[clause][item];
                const int value = next_fixed[std::abs(literal) - 1];
                if (value < 0) next[next_m][out_length++] = literal;
                else if ((literal > 0) == (value != 0)) { satisfied = true; break; }
            }
            if (!satisfied) next_lengths[next_m++] = out_length;
        }
        for (int clause = 0; clause < next_m; ++clause) {
            current_lengths[clause] = next_lengths[clause];
            for (int item = 0; item < next_lengths[clause]; ++item)
                current[clause][item] = next[clause][item];
        }
        current_m = next_m;
        for (int variable = 0; variable < n; ++variable) fixed[variable] = next_fixed[variable];
        ++depth;
        if (depth > n) return -1;
    }
    if (!found) mask = 0;
    const std::int64_t staged[6] = {found, mask, stats.calls, stats.unit_forces,
                                    stats.random_guesses, stats.max_depth};
    if (output == nullptr || capacity < 48) return -2;
    for (std::size_t word = 0; word < 6; ++word) put_i64(output, word, staged[word]);
    return 48;
}

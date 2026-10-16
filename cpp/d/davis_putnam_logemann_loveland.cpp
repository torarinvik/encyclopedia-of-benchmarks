#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_VARIABLES = 5;
constexpr int MAX_CLAUSES = 10;
constexpr int MAX_CLAUSE_LENGTH = 5;
constexpr std::size_t MAX_INPUT_LENGTH = 2 + MAX_CLAUSES * (1 + MAX_CLAUSE_LENGTH);

bool dpll(const std::uint8_t positive[MAX_CLAUSES], const std::uint8_t negative[MAX_CLAUSES],
          int variable_count, int clause_count, std::uint8_t assigned, std::uint8_t truth) {
    const auto universe = static_cast<std::uint8_t>((1u << variable_count) - 1u);
    for (;;) {
        bool changed = false;
        bool all_satisfied = true;
        for (int clause = 0; clause < clause_count; ++clause) {
            const auto pos = positive[clause], neg = negative[clause];
            if ((pos & neg) != 0 || (pos & truth) != 0 || (neg & (assigned & static_cast<std::uint8_t>(~truth))) != 0) continue;
            all_satisfied = false;
            const auto open = static_cast<std::uint8_t>((pos | neg) & universe & static_cast<std::uint8_t>(~assigned));
            if (open == 0) return false;
            if ((open & static_cast<std::uint8_t>(open - 1u)) == 0) {
                if ((pos & open) != 0) truth |= open;
                else truth &= static_cast<std::uint8_t>(~open);
                assigned |= open;
                changed = true;
                break;
            }
        }
        if (all_satisfied) return true;
        if (changed) continue;
        std::uint8_t positive_occurrences = 0, negative_occurrences = 0;
        for (int clause = 0; clause < clause_count; ++clause) {
            const auto pos = positive[clause], neg = negative[clause];
            if ((pos & neg) != 0 || (pos & truth) != 0 || (neg & (assigned & static_cast<std::uint8_t>(~truth))) != 0) continue;
            const auto open = static_cast<std::uint8_t>((pos | neg) & universe & static_cast<std::uint8_t>(~assigned));
            positive_occurrences |= static_cast<std::uint8_t>(pos & open);
            negative_occurrences |= static_cast<std::uint8_t>(neg & open);
        }
        const auto pure_true = static_cast<std::uint8_t>(positive_occurrences & static_cast<std::uint8_t>(~negative_occurrences));
        const auto pure_false = static_cast<std::uint8_t>(negative_occurrences & static_cast<std::uint8_t>(~positive_occurrences));
        const auto pure = static_cast<std::uint8_t>(pure_true | pure_false);
        if (pure != 0) {
            truth = static_cast<std::uint8_t>((truth | pure_true) & static_cast<std::uint8_t>(~pure_false));
            assigned |= pure;
            continue;
        }
        break;
    }
    for (int variable = 0; variable < variable_count; ++variable) {
        const auto bit = static_cast<std::uint8_t>(1u << variable);
        if ((assigned & bit) == 0)
            return dpll(positive, negative, variable_count, clause_count, static_cast<std::uint8_t>(assigned | bit),
                        static_cast<std::uint8_t>(truth | bit)) ||
                   dpll(positive, negative, variable_count, clause_count, static_cast<std::uint8_t>(assigned | bit),
                        static_cast<std::uint8_t>(truth & static_cast<std::uint8_t>(~bit)));
    }
    return false;
}
}

extern "C" std::int64_t davis_putnam_logemann_loveland(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const auto variable_arg = values[0], clause_arg = values[1];
    if (variable_arg < 0 || variable_arg > MAX_VARIABLES || clause_arg < 0 || clause_arg > MAX_CLAUSES) return -1;
    const int variable_count = static_cast<int>(variable_arg), clause_count = static_cast<int>(clause_arg);
    std::uint8_t positive[MAX_CLAUSES] = {}, negative[MAX_CLAUSES] = {};
    std::size_t position = 2;
    for (int clause = 0; clause < clause_count; ++clause) {
        if (position >= length) return -1;
        const auto literal_count = values[position++];
        if (literal_count < 0 || literal_count > MAX_CLAUSE_LENGTH || static_cast<std::size_t>(literal_count) > length - position) return -1;
        for (std::int64_t item = 0; item < literal_count; ++item) {
            const auto literal = values[position++];
            if (literal == 0 || literal < -variable_count || literal > variable_count) return -1;
            const auto bit = static_cast<std::uint8_t>(1u << static_cast<unsigned>(literal < 0 ? -literal : literal) - 1u);
            if (literal > 0) positive[clause] |= bit;
            else negative[clause] |= bit;
        }
    }
    if (position != length) return -1;
    return dpll(positive, negative, variable_count, clause_count, 0, 0) ? 1 : 0;
}

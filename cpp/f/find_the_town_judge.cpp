/* Find the unique person trusted by everyone else and who trusts nobody. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_people = 1000;
constexpr std::int64_t max_trust_rows = 10000;
}

extern "C" std::int64_t find_the_town_judge(const std::int64_t *values,
        std::size_t length) noexcept {
    if (length < 2 || length > 20002 || values == nullptr) return -2;
    const auto people = values[0], trust_count = values[1];
    if (people < 1 || people > max_people || trust_count < 0 || trust_count > max_trust_rows)
        return -2;
    if (length != 2 + 2 * static_cast<std::size_t>(trust_count)) return -2;

    std::array<std::size_t, 1001> incoming{}, outgoing{};
    for (std::size_t edge = 0; edge < static_cast<std::size_t>(trust_count); ++edge) {
        const auto from = values[2 + 2 * edge], to = values[3 + 2 * edge];
        if (from < 1 || from > people || to < 1 || to > people || from == to) return -2;
        ++outgoing[static_cast<std::size_t>(from)];
        ++incoming[static_cast<std::size_t>(to)];
    }
    std::int64_t judge = -1;
    for (std::int64_t person = 1; person <= people; ++person) {
        if (incoming[static_cast<std::size_t>(person)] == static_cast<std::size_t>(people - 1) &&
            outgoing[static_cast<std::size_t>(person)] == 0) {
            if (judge != -1) return -1;
            judge = person;
        }
    }
    return judge;
}

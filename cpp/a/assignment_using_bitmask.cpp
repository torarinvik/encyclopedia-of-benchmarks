/* Count task assignments with one distinct eligible task per person. */
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t assignment_using_bitmask(const std::int64_t *input,
                                                  std::size_t length) noexcept
{
    if (length < 2) return -1;
    const auto people = input[0];
    const auto tasks = input[1];
    if (people < 0 || people > 10 || tasks < 0 || tasks > 10
        || length != static_cast<std::size_t>(2 + people)) return -1;
    const auto valid_tasks = std::uint64_t{1} << static_cast<unsigned>(tasks);
    for (std::size_t person = 0; person < static_cast<std::size_t>(people); ++person)
        if (input[2 + person] < 0 || static_cast<std::uint64_t>(input[2 + person]) >= valid_tasks) return -1;

    const auto states = std::size_t{1} << static_cast<unsigned>(people);
    std::array<std::int64_t, 4096> ways{};
    std::array<std::int64_t, 4096> next{};
    ways[0] = 1;
    for (std::int64_t task = 0; task < tasks; ++task) {
        next.fill(0);
        for (std::size_t mask = 0; mask < states; ++mask) {
            const auto count = ways[mask];
            if (count == 0) continue;
            next[mask] += count;
            for (std::size_t person = 0; person < static_cast<std::size_t>(people); ++person) {
                const auto bit = std::size_t{1} << person;
                if ((mask & bit) == 0 && (input[2 + person] & (std::int64_t{1} << task)) != 0)
                    next[mask | bit] += count;
            }
        }
        ways = next;
    }
    return ways[states - 1];
}

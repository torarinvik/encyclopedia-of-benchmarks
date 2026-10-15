#include <cstddef>
#include <cstdint>
extern "C" std::int64_t josephus_problem_simulation(const std::int64_t *values, std::size_t length) noexcept {
    if (length != 2) return -1;
    const auto n_value = values[0], step = values[1];
    if (n_value < 1 || n_value > 512 || step < 1) return -1;
    std::int64_t people[512];
    auto remaining = static_cast<std::size_t>(n_value);
    for (std::size_t i = 0; i < remaining; ++i) people[i] = static_cast<std::int64_t>(i) + 1;
    std::size_t current = 0;
    while (remaining > 1) {
        const auto offset = static_cast<std::size_t>((step - 1) % static_cast<std::int64_t>(remaining));
        const auto removed = (current + offset) % remaining;
        for (std::size_t i = removed; i + 1 < remaining; ++i) people[i] = people[i + 1];
        --remaining;
        current = removed % remaining;
    }
    return people[0];
}

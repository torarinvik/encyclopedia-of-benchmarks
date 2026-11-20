#include <cstddef>
#include <cstdint>

extern "C" std::int64_t paint_house_iii(const std::int64_t *input, std::size_t length) noexcept
{
    constexpr std::size_t max_input = 44;
    constexpr std::int64_t infinity = 801;
    if (input == nullptr || length < 3 || length > max_input) return -1;
    const auto m_value = input[0], n_value = input[1], target_value = input[2];
    if (m_value < 1 || m_value > 8 || n_value < 1 || n_value > 4
        || target_value < 1 || target_value > m_value) return -1;
    const auto m = static_cast<std::size_t>(m_value);
    const auto n = static_cast<std::size_t>(n_value);
    const auto target = static_cast<std::size_t>(target_value);
    if (length != 3 + m + m * n) return -1;
    const std::size_t houses_at = 3, costs_at = 3 + m;
    for (std::size_t i = 0; i < m; ++i)
        if (input[houses_at + i] < 0 || input[houses_at + i] > n_value) return -1;
    for (std::size_t i = 0; i < m * n; ++i)
        if (input[costs_at + i] < 0 || input[costs_at + i] > 100) return -1;

    const auto at = [](std::size_t color, std::size_t groups) { return color * 9 + groups; };
    std::int64_t previous[45];
    std::int64_t current[45];
    for (std::size_t i = 0; i < 45; ++i) previous[i] = infinity;
    const auto first = input[houses_at];
    for (std::size_t color = 1; color <= n; ++color)
        if (first == 0 || first == static_cast<std::int64_t>(color))
            previous[at(color, 1)] = first == 0 ? input[costs_at + color - 1] : 0;

    for (std::size_t house = 1; house < m; ++house) {
        for (std::size_t i = 0; i < 45; ++i) current[i] = infinity;
        const auto fixed = input[houses_at + house];
        for (std::size_t color = 1; color <= n; ++color) {
            if (fixed != 0 && fixed != static_cast<std::int64_t>(color)) continue;
            const auto paint_cost = fixed == 0 ? input[costs_at + house * n + color - 1] : 0;
            for (std::size_t groups = 1; groups <= target; ++groups) {
                auto best = infinity;
                for (std::size_t old_color = 1; old_color <= n; ++old_color) {
                    const auto old_groups = groups - (old_color != color ? 1 : 0);
                    if (old_groups >= 1 && previous[at(old_color, old_groups)] < best)
                        best = previous[at(old_color, old_groups)];
                }
                if (best < infinity) current[at(color, groups)] = best + paint_cost;
            }
        }
        for (std::size_t i = 0; i < 45; ++i) previous[i] = current[i];
    }
    auto answer = infinity;
    for (std::size_t color = 1; color <= n; ++color)
        if (previous[at(color, target)] < answer) answer = previous[at(color, target)];
    return answer >= infinity ? -1 : answer;
}

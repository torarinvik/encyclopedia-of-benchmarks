#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t ANT_LIMIT = 64;
constexpr std::size_t ITERATION_LIMIT = 64;
constexpr double INVALID_RESULT = -1.0e300;
using Cities = std::array<std::array<std::int64_t, 2>, 3>;
using Pheromones = std::array<std::array<double, 3>, 3>;

double city_distance(const Cities &cities, std::size_t first, std::size_t second) noexcept
{
    const double dx = static_cast<double>(cities[first][0]) - static_cast<double>(cities[second][0]);
    const double dy = static_cast<double>(cities[first][1]) - static_cast<double>(cities[second][1]);
    return std::sqrt(dx * dx + dy * dy);
}

double next_random_fraction(std::int64_t &state) noexcept
{
    state = (state * INT64_C(48271)) % INT64_C(2147483647);
    return static_cast<double>(state) / 2147483647.0;
}

std::size_t select_next_city(std::size_t current, unsigned visited, const Cities &cities,
                             const Pheromones &pheromones, std::int64_t &random_state) noexcept
{
    std::array<double, 3> scores{};
    double total = 0.0;
    for (std::size_t city = 0; city < 3; ++city) {
        if ((visited & (1u << city)) != 0) continue;
        const double heuristic = 1.0 / city_distance(cities, current, city);
        const double squared = heuristic * heuristic;
        const double fifth = squared * squared * heuristic;
        scores[city] = pheromones[current][city] * fifth;
        total += scores[city];
    }
    const double roll = next_random_fraction(random_state) * total;
    double cumulative = 0.0;
    std::size_t fallback = 0;
    for (std::size_t city = 0; city < 3; ++city) {
        if ((visited & (1u << city)) != 0) continue;
        fallback = city;
        cumulative += scores[city];
        if (cumulative >= roll) return city;
    }
    return fallback;
}
}

extern "C" double ant_colony_optimization(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length != 8 || input[0] < 1 || input[0] > static_cast<std::int64_t>(ANT_LIMIT) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(ITERATION_LIMIT)) return INVALID_RESULT;
    Cities cities{};
    for (std::size_t city = 0; city < 3; ++city) {
        cities[city][0] = input[2 + 2 * city];
        cities[city][1] = input[3 + 2 * city];
        if (cities[city][0] < -100000 || cities[city][0] > 100000 ||
            cities[city][1] < -100000 || cities[city][1] > 100000) return INVALID_RESULT;
        for (std::size_t previous = 0; previous < city; ++previous)
            if (cities[city] == cities[previous]) return INVALID_RESULT;
    }

    const auto ant_count = static_cast<std::size_t>(input[0]);
    const auto iteration_count = static_cast<std::size_t>(input[1]);
    Pheromones pheromones{};
    for (auto &row : pheromones) row.fill(1.0);
    std::array<std::array<std::size_t, 4>, ANT_LIMIT> routes{};
    std::int64_t random_state = 1;
    double best_distance = std::numeric_limits<double>::infinity();

    for (std::size_t iteration = 0; iteration < iteration_count; ++iteration) {
        for (std::size_t ant = 0; ant < ant_count; ++ant) {
            routes[ant][0] = 0;
            std::size_t current = 0;
            unsigned visited = 1u;
            for (std::size_t step = 1; step < 3; ++step) {
                current = select_next_city(current, visited, cities, pheromones, random_state);
                routes[ant][step] = current;
                visited |= 1u << current;
            }
            routes[ant][3] = 0;
            double distance = 0.0;
            for (std::size_t edge = 0; edge < 3; ++edge)
                distance += city_distance(cities, routes[ant][edge], routes[ant][edge + 1]);
            if (distance < best_distance) best_distance = distance;
        }
        for (auto &row : pheromones) for (double &value : row) value *= 0.7;
        for (std::size_t ant = 0; ant < ant_count; ++ant) {
            double distance = 0.0;
            for (std::size_t edge = 0; edge < 3; ++edge)
                distance += city_distance(cities, routes[ant][edge], routes[ant][edge + 1]);
            const double deposit = 10.0 / distance;
            for (std::size_t edge = 0; edge < 3; ++edge) {
                const auto from = routes[ant][edge];
                const auto to = routes[ant][edge + 1];
                pheromones[from][to] += deposit;
                pheromones[to][from] += deposit;
            }
        }
    }
    return best_distance;
}

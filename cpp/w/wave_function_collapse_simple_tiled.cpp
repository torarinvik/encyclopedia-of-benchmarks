#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxCells = 16;
constexpr std::size_t MaxTiles = 4;
constexpr std::size_t MaxParseableInputLength = 56;

unsigned popcount_small(std::uint8_t mask) noexcept
{
    unsigned count = 0;
    while (mask != 0) { mask = static_cast<std::uint8_t>(mask & (mask - 1)); ++count; }
    return count;
}

bool propagate(std::uint8_t *domains, const std::uint8_t *compatibility,
               std::size_t width, std::size_t height, std::size_t tile_count,
               std::size_t start_cell, bool seed_all) noexcept
{
    const std::size_t cell_count = width * height;
    std::size_t queue[MaxCells]{};
    bool in_queue[MaxCells]{};
    std::size_t head = 0, tail = 0, queued = 0;
    if (seed_all) {
        for (std::size_t cell = 0; cell < cell_count; ++cell) {
            queue[tail] = cell;
            tail = (tail + 1) % cell_count;
            ++queued;
            in_queue[cell] = true;
        }
    } else {
        queue[tail] = start_cell;
        tail = (tail + 1) % cell_count;
        ++queued;
        in_queue[start_cell] = true;
    }

    while (queued != 0) {
        const std::size_t source = queue[head];
        head = (head + 1) % cell_count;
        --queued;
        in_queue[source] = false;
        const std::size_t row = source / width, column = source % width;
        for (std::size_t direction = 0; direction < 4; ++direction) {
            std::size_t neighbor = 0;
            bool has_neighbor = false;
            if (direction == 0 && row != 0) { neighbor = source - width; has_neighbor = true; }
            else if (direction == 1 && column + 1 < width) { neighbor = source + 1; has_neighbor = true; }
            else if (direction == 2 && row + 1 < height) { neighbor = source + width; has_neighbor = true; }
            else if (direction == 3 && column != 0) { neighbor = source - 1; has_neighbor = true; }
            if (!has_neighbor) continue;
            std::uint8_t supported = 0;
            for (std::size_t tile = 0; tile < tile_count; ++tile)
                if ((domains[source] & static_cast<std::uint8_t>(1u << tile)) != 0)
                    supported = static_cast<std::uint8_t>(supported | compatibility[direction * tile_count + tile]);
            const std::uint8_t reduced = static_cast<std::uint8_t>(domains[neighbor] & supported);
            if (reduced == domains[neighbor]) continue;
            domains[neighbor] = reduced;
            if (reduced == 0) return false;
            if (!in_queue[neighbor]) {
                queue[tail] = neighbor;
                tail = (tail + 1) % cell_count;
                ++queued;
                in_queue[neighbor] = true;
            }
        }
    }
    return true;
}
}

extern "C" std::int64_t wave_function_collapse_simple_tiled(const std::int64_t *input,
                                                              std::size_t length) noexcept
{
    if (input == nullptr || length < 3 || length > MaxParseableInputLength) return -1;
    if (input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 4 || input[2] < 1 || input[2] > 4) return -1;
    const std::size_t width = static_cast<std::size_t>(input[0]);
    const std::size_t height = static_cast<std::size_t>(input[1]);
    const std::size_t tile_count = static_cast<std::size_t>(input[2]);
    const std::size_t cell_count = width * height;
    if (length != 3 + 2 * cell_count + 5 * tile_count) return -1;
    const std::uint8_t full_mask = static_cast<std::uint8_t>((1u << tile_count) - 1u);
    std::uint8_t domains[MaxCells]{};
    std::uint8_t weights[MaxTiles]{};
    std::uint8_t compatibility[4 * MaxTiles]{};
    std::uint16_t draws[MaxCells]{};
    std::size_t position = 3;
    for (std::size_t cell = 0; cell < cell_count; ++cell) {
        if (input[position] < 1 || input[position] > full_mask) return -1;
        domains[cell] = static_cast<std::uint8_t>(input[position++]);
    }
    for (std::size_t tile = 0; tile < tile_count; ++tile) {
        if (input[position] < 1 || input[position] > 4) return -1;
        weights[tile] = static_cast<std::uint8_t>(input[position++]);
    }
    for (std::size_t direction = 0; direction < 4; ++direction) {
        for (std::size_t tile = 0; tile < tile_count; ++tile) {
            if (input[position] < 0 || input[position] > full_mask) return -1;
            compatibility[direction * tile_count + tile] = static_cast<std::uint8_t>(input[position++]);
        }
    }
    for (std::size_t cell = 0; cell < cell_count; ++cell) {
        if (input[position] < 0 || input[position] > 65535) return -1;
        draws[cell] = static_cast<std::uint16_t>(input[position++]);
    }

    for (std::size_t first = 0; first < tile_count; ++first) {
        for (std::size_t second = 0; second < tile_count; ++second) {
            const bool north = (compatibility[first] & static_cast<std::uint8_t>(1u << second)) != 0;
            const bool south_reverse =
                (compatibility[2 * tile_count + second] & static_cast<std::uint8_t>(1u << first)) != 0;
            const bool east = (compatibility[tile_count + first] & static_cast<std::uint8_t>(1u << second)) != 0;
            const bool west_reverse =
                (compatibility[3 * tile_count + second] & static_cast<std::uint8_t>(1u << first)) != 0;
            if (north != south_reverse || east != west_reverse) return -1;
        }
    }

    if (!propagate(domains, compatibility, width, height, tile_count, 0, true)) return -2;
    for (;;) {
        std::size_t best_cell = cell_count;
        unsigned best_count = static_cast<unsigned>(MaxTiles + 1);
        for (std::size_t cell = 0; cell < cell_count; ++cell) {
            const unsigned count = popcount_small(domains[cell]);
            if (count > 1 && count < best_count) { best_cell = cell; best_count = count; }
        }
        if (best_cell == cell_count) break;
        unsigned total_weight = 0;
        for (std::size_t tile = 0; tile < tile_count; ++tile)
            if ((domains[best_cell] & static_cast<std::uint8_t>(1u << tile)) != 0) total_weight += weights[tile];
        unsigned rank = static_cast<unsigned>(draws[best_cell]) * total_weight / 65536u;
        std::size_t selected = tile_count;
        for (std::size_t tile = 0; tile < tile_count; ++tile) {
            if ((domains[best_cell] & static_cast<std::uint8_t>(1u << tile)) == 0) continue;
            if (rank < weights[tile]) { selected = tile; break; }
            rank -= weights[tile];
        }
        if (selected == tile_count) return -2;
        domains[best_cell] = static_cast<std::uint8_t>(1u << selected);
        if (!propagate(domains, compatibility, width, height, tile_count, best_cell, false)) return -2;
    }
    std::uint64_t result = UINT64_C(1) << 32;
    for (std::size_t cell = 0; cell < cell_count; ++cell) {
        std::size_t tile = 0;
        while ((domains[cell] & static_cast<std::uint8_t>(1u << tile)) == 0) ++tile;
        result |= static_cast<std::uint64_t>(tile) << (2 * cell);
    }
    return static_cast<std::int64_t>(result);
}

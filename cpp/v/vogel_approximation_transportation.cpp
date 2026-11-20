#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 18;
constexpr std::int64_t allocation_base = 262144;
}

extern "C" std::int64_t vogel_approximation_transportation(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 5 || length > max_length) return -1;
    if (input[0] < 1 || input[0] > 3 || input[1] < 1 || input[1] > 3) return -1;
    const auto rows = static_cast<std::size_t>(input[0]);
    const auto cols = static_cast<std::size_t>(input[1]);
    const auto cell_count = rows * cols;
    if (length != 2 + cell_count + rows + cols) return -1;
    std::array<std::int64_t, 9> costs{};
    std::array<std::int64_t, 3> supply{};
    std::array<std::int64_t, 3> demand{};
    std::size_t offset = 2;
    for (std::size_t i = 0; i < cell_count; ++i) {
        if (input[offset + i] < 0 || input[offset + i] > 9) return -1;
        costs[i] = input[offset + i];
    }
    offset += cell_count;
    std::int64_t supply_total = 0, demand_total = 0;
    for (std::size_t i = 0; i < rows; ++i) {
        if (input[offset + i] < 1 || input[offset + i] > 3) return -1;
        supply[i] = input[offset + i]; supply_total += supply[i];
    }
    offset += rows;
    for (std::size_t j = 0; j < cols; ++j) {
        if (input[offset + j] < 1 || input[offset + j] > 3) return -1;
        demand[j] = input[offset + j]; demand_total += demand[j];
    }
    if (supply_total != demand_total) return -1;

    std::array<bool, 3> active_rows{true, true, true};
    std::array<bool, 3> active_cols{true, true, true};
    std::array<std::int64_t, 9> allocation{};
    std::int64_t objective = 0;
    auto remaining = supply_total;
    while (remaining > 0) {
        int best_kind = -1;
        std::size_t best_line = 0;
        std::int64_t best_penalty = -1;
        for (int kind = 0; kind < 2; ++kind) {
            const auto line_count = kind == 0 ? rows : cols;
            const auto partner_count = kind == 0 ? cols : rows;
            for (std::size_t line = 0; line < line_count; ++line) {
                if (!(kind == 0 ? active_rows[line] : active_cols[line])) continue;
                std::int64_t first = 10, second = 10;
                std::size_t count = 0;
                for (std::size_t partner = 0; partner < partner_count; ++partner) {
                    if (!(kind == 0 ? active_cols[partner] : active_rows[partner])) continue;
                    const auto row = kind == 0 ? line : partner;
                    const auto col = kind == 0 ? partner : line;
                    const auto value = costs[row * cols + col];
                    if (value < first) { second = first; first = value; }
                    else if (value < second) { second = value; }
                    ++count;
                }
                if (count == 0) continue;
                const auto penalty = count == 1 ? 10 : second - first;
                if (penalty > best_penalty) {
                    best_penalty = penalty; best_kind = kind; best_line = line;
                }
            }
        }
        if (best_kind < 0) return -1;
        const auto partner_count = best_kind == 0 ? cols : rows;
        auto best_partner = partner_count;
        std::int64_t best_cost = 10;
        for (std::size_t partner = 0; partner < partner_count; ++partner) {
            if (!(best_kind == 0 ? active_cols[partner] : active_rows[partner])) continue;
            const auto row = best_kind == 0 ? best_line : partner;
            const auto col = best_kind == 0 ? partner : best_line;
            const auto value = costs[row * cols + col];
            if (value < best_cost) { best_cost = value; best_partner = partner; }
        }
        if (best_partner == partner_count) return -1;
        const auto row = best_kind == 0 ? best_line : best_partner;
        const auto col = best_kind == 0 ? best_partner : best_line;
        const auto amount = supply[row] < demand[col] ? supply[row] : demand[col];
        allocation[row * 3 + col] = amount;
        objective += amount * costs[row * cols + col];
        supply[row] -= amount; demand[col] -= amount; remaining -= amount;
        if (supply[row] == 0) active_rows[row] = false;
        if (demand[col] == 0) active_cols[col] = false;
    }
    std::int64_t signature = 0, place = 1;
    for (const auto quantity : allocation) { signature += quantity * place; place *= 4; }
    return objective * allocation_base + signature;
}

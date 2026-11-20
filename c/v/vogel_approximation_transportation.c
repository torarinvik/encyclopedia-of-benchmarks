#include <stddef.h>
#include <stdint.h>

enum { MAX_LENGTH = 18, MAX_ROWS = 3, MAX_COLS = 3, MAX_COST = 9 };

int64_t vogel_approximation_transportation(const int64_t *input, size_t length) {
    if (input == NULL || length < 5 || length > MAX_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_ROWS || input[1] < 1 || input[1] > MAX_COLS)
        return -1;
    const size_t rows = (size_t)input[0];
    const size_t cols = (size_t)input[1];
    const size_t cost_count = rows * cols;
    if (length != 2 + cost_count + rows + cols) return -1;

    int64_t costs[9] = {0}, supply[3] = {0}, demand[3] = {0};
    size_t offset = 2;
    for (size_t i = 0; i < cost_count; ++i) {
        if (input[offset + i] < 0 || input[offset + i] > MAX_COST) return -1;
        costs[i] = input[offset + i];
    }
    offset += cost_count;
    int64_t total_supply = 0, total_demand = 0;
    for (size_t i = 0; i < rows; ++i) {
        if (input[offset + i] < 1 || input[offset + i] > 3) return -1;
        supply[i] = input[offset + i];
        total_supply += supply[i];
    }
    offset += rows;
    for (size_t j = 0; j < cols; ++j) {
        if (input[offset + j] < 1 || input[offset + j] > 3) return -1;
        demand[j] = input[offset + j];
        total_demand += demand[j];
    }
    if (total_supply != total_demand) return -1;

    int active_rows[3] = {1, 1, 1};
    int active_cols[3] = {1, 1, 1};
    int64_t allocation[9] = {0};
    int64_t total_cost = 0;
    int64_t remaining = total_supply;
    while (remaining > 0) {
        int best_kind = -1;
        size_t best_line = 0;
        int64_t best_penalty = -1;
        for (int kind = 0; kind < 2; ++kind) {
            const size_t line_count = kind == 0 ? rows : cols;
            const size_t partner_count = kind == 0 ? cols : rows;
            for (size_t line = 0; line < line_count; ++line) {
                if (!(kind == 0 ? active_rows[line] : active_cols[line])) continue;
                int64_t smallest = MAX_COST + 1;
                int64_t second = MAX_COST + 1;
                size_t found = 0;
                for (size_t partner = 0; partner < partner_count; ++partner) {
                    if (!(kind == 0 ? active_cols[partner] : active_rows[partner])) continue;
                    const size_t row = kind == 0 ? line : partner;
                    const size_t col = kind == 0 ? partner : line;
                    const int64_t cost = costs[row * cols + col];
                    if (cost < smallest) { second = smallest; smallest = cost; }
                    else if (cost < second) { second = cost; }
                    ++found;
                }
                if (found == 0) continue;
                const int64_t penalty = found == 1 ? 10 : second - smallest;
                if (penalty > best_penalty) {
                    best_penalty = penalty;
                    best_kind = kind;
                    best_line = line;
                }
            }
        }
        if (best_kind < 0) return -1;

        const size_t partner_count = best_kind == 0 ? cols : rows;
        size_t best_partner = partner_count;
        int64_t cheapest = MAX_COST + 1;
        for (size_t partner = 0; partner < partner_count; ++partner) {
            if (!(best_kind == 0 ? active_cols[partner] : active_rows[partner])) continue;
            const size_t row = best_kind == 0 ? best_line : partner;
            const size_t col = best_kind == 0 ? partner : best_line;
            const int64_t cost = costs[row * cols + col];
            if (cost < cheapest) { cheapest = cost; best_partner = partner; }
        }
        if (best_partner == partner_count) return -1;
        const size_t row = best_kind == 0 ? best_line : best_partner;
        const size_t col = best_kind == 0 ? best_partner : best_line;
        const int64_t quantity = supply[row] < demand[col] ? supply[row] : demand[col];
        allocation[row * 3 + col] = quantity;
        total_cost += quantity * costs[row * cols + col];
        supply[row] -= quantity;
        demand[col] -= quantity;
        remaining -= quantity;
        if (supply[row] == 0) active_rows[row] = 0;
        if (demand[col] == 0) active_cols[col] = 0;
    }

    int64_t signature = 0;
    int64_t place = 1;
    for (size_t cell = 0; cell < 9; ++cell) {
        signature += allocation[cell] * place;
        place *= 4;
    }
    return total_cost * place + signature;
}

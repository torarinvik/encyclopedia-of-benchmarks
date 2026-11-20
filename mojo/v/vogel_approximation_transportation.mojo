from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("vogel_approximation_transportation")
fn vogel_approximation_transportation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 18:
        return -1
    let rows_value = input[0]
    let cols_value = input[1]
    if rows_value < 1 or rows_value > 3 or cols_value < 1 or cols_value > 3:
        return -1
    let rows = Int(rows_value)
    let cols = Int(cols_value)
    let cell_count = rows * cols
    if length != c_size_t(2 + cell_count + rows + cols):
        return -1

    var costs = InlineArray[Int64, 9](fill=0)
    var supply = InlineArray[Int64, 3](fill=0)
    var demand = InlineArray[Int64, 3](fill=0)
    var offset = 2
    for i in range(cell_count):
        let value = input[offset + i]
        if value < 0 or value > 9:
            return -1
        costs[i] = value
    offset += cell_count
    var supply_total: Int64 = 0
    for i in range(rows):
        let value = input[offset + i]
        if value < 1 or value > 3:
            return -1
        supply[i] = value
        supply_total += value
    offset += rows
    var demand_total: Int64 = 0
    for j in range(cols):
        let value = input[offset + j]
        if value < 1 or value > 3:
            return -1
        demand[j] = value
        demand_total += value
    if supply_total != demand_total:
        return -1

    var active_rows = InlineArray[Bool, 3](fill=True)
    var active_cols = InlineArray[Bool, 3](fill=True)
    var allocation = InlineArray[Int64, 9](fill=0)
    var total_cost: Int64 = 0
    var remaining = supply_total
    while remaining > 0:
        var best_kind = -1
        var best_line = 0
        var best_penalty: Int64 = -1
        for kind in range(2):
            let line_count = rows if kind == 0 else cols
            let partner_count = cols if kind == 0 else rows
            for line in range(line_count):
                if not (active_rows[line] if kind == 0 else active_cols[line]):
                    continue
                var first: Int64 = 10
                var second: Int64 = 10
                var found = 0
                for partner in range(partner_count):
                    if not (active_cols[partner] if kind == 0 else active_rows[partner]):
                        continue
                    let row = line if kind == 0 else partner
                    let col = partner if kind == 0 else line
                    let value = costs[row * cols + col]
                    if value < first:
                        second = first
                        first = value
                    elif value < second:
                        second = value
                    found += 1
                if found == 0:
                    continue
                let penalty: Int64 = 10 if found == 1 else second - first
                if penalty > best_penalty:
                    best_penalty = penalty
                    best_kind = kind
                    best_line = line
        if best_kind < 0:
            return -1

        let partner_count = cols if best_kind == 0 else rows
        var best_partner = partner_count
        var cheapest: Int64 = 10
        for partner in range(partner_count):
            if not (active_cols[partner] if best_kind == 0 else active_rows[partner]):
                continue
            let row = best_line if best_kind == 0 else partner
            let col = partner if best_kind == 0 else best_line
            let value = costs[row * cols + col]
            if value < cheapest:
                cheapest = value
                best_partner = partner
        if best_partner == partner_count:
            return -1
        let row = best_line if best_kind == 0 else best_partner
        let col = best_partner if best_kind == 0 else best_line
        let quantity = supply[row] if supply[row] < demand[col] else demand[col]
        allocation[row * 3 + col] = quantity
        total_cost += quantity * costs[row * cols + col]
        supply[row] -= quantity
        demand[col] -= quantity
        remaining -= quantity
        if supply[row] == 0:
            active_rows[row] = False
        if demand[col] == 0:
            active_cols[col] = False

    var signature: Int64 = 0
    var place: Int64 = 1
    for cell in range(9):
        signature += allocation[cell] * place
        place *= 4
    return total_cost * place + signature

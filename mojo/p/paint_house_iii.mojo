from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_INPUT = 44
comptime INF = 801

@export("paint_house_iii")
fn paint_house_iii(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT:
        return -1
    let m_value = input[0]
    let n_value = input[1]
    let target_value = input[2]
    if m_value < 1 or m_value > 8 or n_value < 1 or n_value > 4:
        return -1
    if target_value < 1 or target_value > m_value:
        return -1
    let m = Int(m_value)
    let n = Int(n_value)
    let target = Int(target_value)
    if length != c_size_t(3 + m + m * n):
        return -1
    var houses = InlineArray[Int64, 8](fill=0)
    var costs = InlineArray[Int64, 32](fill=0)
    for index in range(m):
        let house = input[3 + index]
        if house < 0 or house > n_value:
            return -1
        houses[index] = house
    for index in range(m * n):
        let cost = input[3 + m + index]
        if cost < 0 or cost > 100:
            return -1
        costs[index] = cost

    var previous = InlineArray[Int64, 45](fill=INF)
    var current = InlineArray[Int64, 45](fill=INF)
    for color in range(1, n + 1):
        if houses[0] == 0 or houses[0] == color:
            previous[color * 9 + 1] = costs[color - 1] if houses[0] == 0 else 0
    for house_index in range(1, m):
        for index in range(45):
            current[index] = INF
        for color in range(1, n + 1):
            if houses[house_index] != 0 and houses[house_index] != color:
                continue
            let paint_cost = costs[house_index * n + color - 1] if houses[house_index] == 0 else 0
            for groups in range(1, target + 1):
                var best: Int64 = INF
                for old_color in range(1, n + 1):
                    let old_groups = groups - (1 if old_color != color else 0)
                    if old_groups >= 1 and previous[old_color * 9 + old_groups] < best:
                        best = previous[old_color * 9 + old_groups]
                if best < INF:
                    current[color * 9 + groups] = best + paint_cost
        for index in range(45):
            previous[index] = current[index]
    var answer: Int64 = INF
    for color in range(1, n + 1):
        if previous[color * 9 + target] < answer:
            answer = previous[color * 9 + target]
    return -1 if answer >= INF else answer

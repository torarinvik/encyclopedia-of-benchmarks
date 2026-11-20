from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime TTC_MAX_AGENTS = 8
comptime TTC_MAX_INPUT = 66

@export("housing_top_trading_cycles")
fn housing_top_trading_cycles(input: UnsafePointer[Int64, ImmutAnyOrigin],
                              length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or length > c_size_t(TTC_MAX_INPUT): return -1
    let n_value = input[0]
    if n_value < 1 or n_value > Int64(TTC_MAX_AGENTS): return -1
    let n = Int(n_value)
    if length != c_size_t(1 + n * n): return -1

    var preference = InlineArray[Int64, TTC_MAX_AGENTS * TTC_MAX_AGENTS](fill=0)
    for agent in range(n):
        var seen = InlineArray[UInt8, TTC_MAX_AGENTS](fill=0)
        for rank in range(n):
            let house = input[1 + agent * n + rank]
            if house < 0 or house >= n_value: return -1
            if seen[Int(house)] != 0: return -1
            seen[Int(house)] = 1
            preference[agent * TTC_MAX_AGENTS + rank] = house

    var remaining = InlineArray[UInt8, TTC_MAX_AGENTS](fill=1)
    var allocation = InlineArray[Int64, TTC_MAX_AGENTS](fill=0)
    var remaining_count = n

    while remaining_count > 0:
        var choice = InlineArray[Int, TTC_MAX_AGENTS](fill=0)
        var successor = InlineArray[Int, TTC_MAX_AGENTS](fill=0)
        var state = InlineArray[UInt8, TTC_MAX_AGENTS](fill=0)
        var path_position = InlineArray[Int, TTC_MAX_AGENTS](fill=0)
        var path = InlineArray[Int, TTC_MAX_AGENTS](fill=0)
        var cycle_member = InlineArray[UInt8, TTC_MAX_AGENTS](fill=0)

        for agent in range(n):
            if remaining[agent] == 0: continue
            var found = False
            for rank in range(n):
                let house = Int(preference[agent * TTC_MAX_AGENTS + rank])
                if remaining[house] != 0:
                    choice[agent] = house
                    successor[agent] = house
                    found = True
                    break
            if not found: return -1

        for start in range(n):
            if remaining[start] == 0 or state[start] != 0: continue
            var path_length = 0
            var current = start
            while state[current] == 0:
                state[current] = 1
                path_position[current] = path_length
                path[path_length] = current
                path_length += 1
                current = successor[current]
            if state[current] == 1:
                let cycle_start = path_position[current]
                for index in range(cycle_start, path_length):
                    cycle_member[path[index]] = 1
            for index in range(path_length):
                state[path[index]] = 2

        var removed = 0
        for agent in range(n):
            if remaining[agent] != 0 and cycle_member[agent] != 0:
                allocation[agent] = Int64(choice[agent])
                remaining[agent] = 0
                remaining_count -= 1
                removed += 1
        if removed == 0: return -1

    var result: Int64 = 0
    for agent in range(n):
        result += allocation[agent] << (3 * agent)
    return result + 1

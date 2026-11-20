from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 4
comptime MAX_F = 3
comptime MAX_INITIAL_COPIES = 4
comptime MAX_COPIES = 644
comptime MAX_CANDIDATE_COPIES = 648
comptime MAX_P = 7
comptime MAX_VALID_INPUT = 62
comptime MAX_PARSEABLE_INPUT = 63
comptime MAX_OUTPUT_BYTES = 5208
comptime NEG_INF = -2305843009213693952

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & 255)

fn insert_sorted(types: List[Int64], kind: Int64) -> List[Int64]:
    var result = List[Int64](capacity=len(types) + 1)
    var inserted = False
    for i in range(len(types)):
        if not inserted and kind < types[i]:
            result.append(kind)
            inserted = True
        result.append(types[i])
    if not inserted:
        result.append(kind)
    return result

fn assign_state(n: Int, f: Int, distances: List[Int64], fees: List[Int64],
                capacities: List[Int64], types: List[Int64], copies: Int) -> List[Int64]:
    let points = n + f
    var multiplicity = List[Int](capacity=f)
    for kind in range(f):
        multiplicity.append(0)
    for copy in range(copies):
        multiplicity[Int(types[copy])] += 1

    var combinations = 1
    for _ in range(n):
        combinations *= f
    var best_service = Int64(9223372036854775807)
    var best_types = List[Int](capacity=n)
    for _ in range(n):
        best_types.append(0)
    for code in range(combinations):
        var candidate = List[Int](capacity=n)
        var loads = List[Int](capacity=f)
        for kind in range(f):
            loads.append(0)
        for _ in range(n):
            candidate.append(0)
        var remainder = code
        var service = Int64(0)
        for offset in range(n):
            let client = n - 1 - offset
            let kind = remainder % f
            remainder = remainder // f
            candidate[client] = kind
            loads[kind] += 1
            service += distances[client * points + n + kind]
        var feasible = True
        for kind in range(f):
            if loads[kind] > multiplicity[kind] * Int(capacities[kind]):
                feasible = False
        if feasible and service < best_service:
            best_service = service
            for client in range(n):
                best_types[client] = candidate[client]

    var assignment = List[Int](capacity=n)
    var copy_loads = List[Int](capacity=copies)
    for copy in range(copies):
        copy_loads.append(0)
    for client in range(n):
        var assigned_copy = -1
        for copy in range(copies):
            let kind = Int(types[copy])
            if assigned_copy == -1 and kind == best_types[client] and copy_loads[copy] < Int(capacities[kind]):
                assigned_copy = copy
                copy_loads[copy] += 1
        assignment.append(assigned_copy)

    var result = List[Int64](capacity=n + 1)
    var total = best_service
    for copy in range(copies):
        total += fees[Int(types[copy])]
    result.append(total)
    for client in range(n):
        result.append(Int64(assignment[client]))
    return result

fn t_hunt(n: Int, f: Int, distances: List[Int64], fees: List[Int64],
          capacities: List[Int64], types: List[Int64], copies: Int,
          assignment: List[Int], target: Int, copies_added: Int) -> List[Int64]:
    let points = n + f
    let limit = min(n, copies_added * Int(capacities[target]))
    var loads = List[Int](capacity=copies)
    var profits = List[Int64](capacity=copies)
    for copy in range(copies):
        loads.append(0)
        profits.append(fees[Int(types[copy])])
    for client in range(n):
        let copy = assignment[client]
        let old_kind = Int(types[copy])
        loads[copy] += 1
        profits[copy] += distances[client * points + n + old_kind] - distances[client * points + n + target]

    var dp = List[Int64](capacity=limit + 1)
    for weight in range(limit + 1):
        dp.append(NEG_INF)
    dp[0] = 0
    var take = List[List[Bool]](capacity=copies)
    for copy in range(copies):
        var row = List[Bool](capacity=limit + 1)
        for weight in range(limit + 1):
            row.append(False)
        take.append(row)
        var next = List[Int64](capacity=limit + 1)
        for weight in range(limit + 1):
            next.append(dp[weight])
        for weight in range(limit + 1):
            let new_weight = weight + loads[copy]
            if dp[weight] != NEG_INF and new_weight <= limit:
                let candidate = dp[weight] + profits[copy]
                if candidate > next[new_weight]:
                    next[new_weight] = candidate
                    take[copy][new_weight] = True
        dp = next

    var best_profit = NEG_INF
    var best_weight = 0
    for weight in range(limit + 1):
        if dp[weight] > best_profit:
            best_profit = dp[weight]
            best_weight = weight
    var selected = List[Int64](capacity=copies)
    for copy in range(copies):
        selected.append(0)
    var used = best_weight
    for offset in range(copies):
        let copy = copies - 1 - offset
        if take[copy][used]:
            selected[copy] = 1
            used -= loads[copy]
    var result = List[Int64](capacity=copies + 1)
    result.append(best_profit)
    for copy in range(copies):
        result.append(selected[copy])
    return result

fn copy_assignments(n: Int, state: List[Int64]) -> List[Int]:
    var result = List[Int](capacity=n)
    for client in range(n):
        result.append(Int(state[client + 1]))
    return result

fn solve_outer(n: Int, f: Int, distances: List[Int64], fees: List[Int64],
               capacities: List[Int64], types: List[Int64]) -> List[Int64]:
    var assignment_state = assign_state(n, f, distances, fees, capacities, types, len(types))
    var assignment = copy_assignments(n, assignment_state)
    var current_cost = assignment_state[0]
    var copies = len(types)
    var accepted_steps = 0
    var current_types = types
    for _ in range(160):
        var moved = False
        for target in range(f):
            let added_types = insert_sorted(current_types, Int64(target))
            let add_state = assign_state(n, f, distances, fees, capacities, added_types, copies + 1)
            if add_state[0] < current_cost:
                current_types = added_types
                copies += 1
                current_cost = add_state[0]
                assignment = copy_assignments(n, add_state)
                accepted_steps += 1
                moved = True
                break
            for copies_added in range(1, n + 1):
                let choice = t_hunt(n, f, distances, fees, capacities, current_types,
                                    copies, assignment, target, copies_added)
                if choice[0] <= Int64(copies_added) * fees[target]:
                    continue
                var candidate_types = List[Int64](capacity=copies + copies_added)
                for copy in range(copies):
                    if choice[copy + 1] == 0:
                        candidate_types.append(current_types[copy])
                for _ in range(copies_added):
                    candidate_types = insert_sorted(candidate_types, Int64(target))
                let next_state = assign_state(n, f, distances, fees, capacities,
                                              candidate_types, len(candidate_types))
                if next_state[0] < current_cost:
                    current_types = candidate_types
                    copies = len(candidate_types)
                    current_cost = next_state[0]
                    assignment = copy_assignments(n, next_state)
                    accepted_steps += 1
                    moved = True
                    break
            if moved:
                break
        if not moved:
            break

    var result = List[Int64](capacity=3 + copies + n)
    result.append(current_cost)
    result.append(Int64(accepted_steps))
    result.append(Int64(copies))
    for copy in range(copies):
        result.append(current_types[copy])
    for client in range(n):
        result.append(Int64(assignment[client]))
    return result

@export("capacitated_facility_location_t_hunt_local_search")
fn capacitated_facility_location_t_hunt_local_search(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 10 or length > MAX_PARSEABLE_INPUT:
        return -1
    let nr, fr, qr = input[0], input[1], input[2]
    if nr < 1 or nr > MAX_N or fr < 1 or fr > MAX_F or qr < 1 or qr > MAX_INITIAL_COPIES:
        return -1
    let n, f, q = Int(nr), Int(fr), Int(qr)
    let points = n + f
    if length != c_size_t(3 + points * points + 2 * f + q):
        return -1
    var distances = List[Int64](capacity=points * points)
    for cell in range(points * points):
        let value = input[3 + cell]
        if value < 0 or value > 20:
            return -1
        distances.append(value)
    for i in range(points):
        if distances[i * points + i] != 0:
            return -1
        for j in range(points):
            let ij = distances[i * points + j]
            if i != j and ij == 0:
                return -1
            if ij != distances[j * points + i]:
                return -1
            for k in range(points):
                if ij > distances[i * points + k] + distances[k * points + j]:
                    return -1
    var at = 3 + points * points
    var fees = List[Int64](capacity=f)
    var capacities = List[Int64](capacity=f)
    var types = List[Int64](capacity=q)
    for kind in range(f):
        let value = input[at]
        at += 1
        if value < 0 or value > 20:
            return -1
        fees.append(value)
    for kind in range(f):
        let value = input[at]
        at += 1
        if value < 1 or value > nr:
            return -1
        capacities.append(value)
    var total_capacity = 0
    for copy in range(q):
        let value = input[at]
        at += 1
        if value < 0 or value >= fr:
            return -1
        types.append(value)
        total_capacity += Int(capacities[Int(value)])
    if total_capacity < n:
        return -1
    for i in range(1, q):
        let value = types[i]
        var j = i
        while j > 0 and types[j - 1] > value:
            types[j] = types[j - 1]
            j -= 1
        types[j] = value

    let result = solve_outer(n, f, distances, fees, capacities, types)
    let needed = 8 * len(result)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed):
        return -2
    for word in range(len(result)):
        put_word(output, word * 8, result[word])
    return Int64(needed)

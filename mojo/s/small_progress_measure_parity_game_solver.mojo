from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn spm_compare(left: InlineArray[Int64, 3], left_top: Bool,
               right: InlineArray[Int64, 3], right_top: Bool) -> Int:
    if left_top != right_top:
        return 1 if left_top else -1
    if left_top:
        return 0
    for index in range(3):
        if left[index] < right[index]:
            return -1
        if left[index] > right[index]:
            return 1
    return 0

@export("small_progress_measure_parity_game_solver")
fn small_progress_measure_parity_game_solver(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 59:
        return -1
    let n_raw = input[0]
    let m_raw = input[1]
    if n_raw < 1 or n_raw > 8 or m_raw < n_raw or m_raw > 20:
        return -1
    let n = Int(n_raw)
    let m = Int(m_raw)
    if length != c_size_t(2 + 2 * n + 2 * m):
        return -1

    var owners = InlineArray[Int64, 8](fill=0)
    var priorities = InlineArray[Int64, 8](fill=0)
    var adjacency = InlineArray[Int64, 8](fill=0)
    var outdegree = InlineArray[Int, 8](fill=0)
    var bounds = InlineArray[Int64, 3](fill=0)
    var measures = InlineArray[Int64, 24](fill=0)
    var tops = InlineArray[Bool, 8](fill=False)
    var cursor = 2
    for vertex in range(n):
        let owner = input[cursor]
        let priority = input[cursor + 1]
        cursor += 2
        if owner < 0 or owner > 1 or priority < 0 or priority > 5:
            return -1
        owners[vertex] = owner
        priorities[vertex] = priority
        if priority == 1:
            bounds[0] += 1
        if priority == 3:
            bounds[1] += 1
        if priority == 5:
            bounds[2] += 1
    for _ in range(m):
        let source_raw = input[cursor]
        let destination_raw = input[cursor + 1]
        cursor += 2
        if source_raw < 0 or source_raw >= n_raw or destination_raw < 0 or destination_raw >= n_raw:
            return -1
        let source = Int(source_raw)
        let destination = Int(destination_raw)
        let bit = Int64(1) << destination
        if adjacency[source] & bit != 0:
            return -1
        adjacency[source] |= bit
        outdegree[source] += 1
    for vertex in range(n):
        if outdegree[vertex] == 0:
            return -1

    var changed = True
    while changed:
        changed = False
        for vertex in range(n):
            var best = InlineArray[Int64, 3](fill=0)
            var best_top = owners[vertex] == 1
            var has_best = False
            for destination in range(n):
                if adjacency[vertex] & (Int64(1) << destination) == 0:
                    continue
                var candidate = InlineArray[Int64, 3](fill=0)
                for index in range(3):
                    candidate[index] = measures[destination * 3 + index]
                var candidate_top = tops[destination]
                if not candidate_top:
                    let priority = priorities[vertex]
                    let included = 0 if priority < 1 else 1 if priority < 3 else 2 if priority < 5 else 3
                    for index in range(included, 3):
                        candidate[index] = 0
                    if priority % 2 == 1:
                        var rank = included - 1
                        var raised = False
                        while rank >= 0 and not raised:
                            if candidate[rank] < bounds[rank]:
                                candidate[rank] += 1
                                for suffix in range(rank + 1, included):
                                    candidate[suffix] = 0
                                raised = True
                            else:
                                candidate[rank] = 0
                                rank -= 1
                        if not raised:
                            candidate_top = True
                let order = spm_compare(candidate, candidate_top, best, best_top)
                if not has_best or (owners[vertex] == 0 and order < 0) or (owners[vertex] == 1 and order > 0):
                    best = candidate
                    best_top = candidate_top
                    has_best = True
            var current = InlineArray[Int64, 3](fill=0)
            for index in range(3):
                current[index] = measures[vertex * 3 + index]
            if spm_compare(current, tops[vertex], best, best_top) < 0:
                for index in range(3):
                    measures[vertex * 3 + index] = best[index]
                tops[vertex] = best_top
                changed = True
    var winners: Int64 = 0
    for vertex in range(n):
        if not tops[vertex]:
            winners |= Int64(1) << vertex
    return winners

from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_VERTICES = 24
comptime MAX_PARSEABLE_INPUT = 26

@fieldwise_init
struct Candidate:
    var vertex: Int = 0
    var bound: Int = 0

@fieldwise_init
struct Search:
    var adjacency: InlineArray[UInt64, MAX_VERTICES] = InlineArray[UInt64, MAX_VERTICES](fill=UInt64(0))
    var chosen: InlineArray[Int, MAX_VERTICES] = InlineArray[Int, MAX_VERTICES](fill=0)
    var chosen_count: Int = 0
    var best: Int = 0
    var steps: InlineArray[Int, MAX_VERTICES + 2] = InlineArray[Int, MAX_VERTICES + 2](fill=0)
    var prior_child_steps: InlineArray[Int, MAX_VERTICES + 2] = InlineArray[Int, MAX_VERTICES + 2](fill=0)
    var total_color_calls: Int = 0

fn degree_order(search: Search, vertices: InlineArray[Int, MAX_VERTICES], count: Int) -> InlineArray[Candidate, MAX_VERTICES]:
    var ids = InlineArray[Int, MAX_VERTICES](fill=0)
    var degrees = InlineArray[Int, MAX_VERTICES](fill=0)
    var maximum_degree = 0
    for i in range(count):
        ids[i] = vertices[i]
        for j in range(count):
            if (search.adjacency[ids[i]] & (UInt64(1) << vertices[j])) != 0:
                degrees[i] += 1
        if degrees[i] > maximum_degree:
            maximum_degree = degrees[i]
    for i in range(1, count):
        let id = ids[i]
        let degree = degrees[i]
        var j = i
        while j > 0 and (degrees[j - 1] < degree or
                         (degrees[j - 1] == degree and ids[j - 1] > id)):
            ids[j] = ids[j - 1]
            degrees[j] = degrees[j - 1]
            j -= 1
        ids[j] = id
        degrees[j] = degree
    var ordered = InlineArray[Candidate, MAX_VERTICES](fill=Candidate())
    for i in range(count):
        ordered[i] = Candidate(ids[i], min(i, maximum_degree) + 1)
    return ordered

fn expand(inout search: Search, candidates: InlineArray[Candidate, MAX_VERTICES], count: Int, level: Int):
    search.steps[level] += search.steps[level - 1] - search.prior_child_steps[level]
    search.prior_child_steps[level] = search.steps[level - 1]
    var remaining_count = count
    while remaining_count > 0:
        if search.chosen_count + candidates[remaining_count - 1].bound <= search.best:
            return
        let vertex = candidates[remaining_count - 1].vertex
        search.chosen[search.chosen_count] = vertex
        search.chosen_count += 1
        var neighbors = InlineArray[Int, MAX_VERTICES](fill=0)
        var neighbor_count = 0
        for i in range(remaining_count - 1):
            let other = candidates[i].vertex
            if (search.adjacency[vertex] & (UInt64(1) << other)) != 0:
                neighbors[neighbor_count] = other
                neighbor_count += 1
        if neighbor_count > 0:
            let prior_steps = search.steps[level]
            search.steps[level] += 1
            search.total_color_calls += 1
            if prior_steps * 1000 < search.total_color_calls * 25:
                let reordered = degree_order(search, neighbors, neighbor_count)
                for i in range(neighbor_count):
                    neighbors[i] = reordered[i].vertex
            var class_masks = InlineArray[UInt64, MAX_VERTICES](fill=UInt64(0))
            var colors = InlineArray[Int, MAX_VERTICES](fill=0)
            var class_count = 0
            for i in range(neighbor_count):
                var color = 0
                while color < class_count and
                      (class_masks[color] & search.adjacency[neighbors[i]]) != 0:
                    color += 1
                if color == class_count:
                    class_count += 1
                colors[i] = color + 1
                class_masks[color] |= UInt64(1) << neighbors[i]
            let minimum_color = max(search.best - search.chosen_count + 1, 1)
            var child = InlineArray[Candidate, MAX_VERTICES](fill=Candidate())
            var child_count = 0
            for color in range(minimum_color, class_count + 1):
                for i in range(neighbor_count):
                    if colors[i] == color:
                        child[child_count] = Candidate(neighbors[i], color)
                        child_count += 1
            expand(search, child, child_count, level + 1)
        elif search.chosen_count > search.best:
            search.best = search.chosen_count
        search.chosen_count -= 1
        remaining_count -= 1

fn solve_konc_maxclique_dyn(values: view[Int64]) -> Int64:
    if values.len() < 1 or values.len() > MAX_PARSEABLE_INPUT:
        return -1
    let n64 = values[0]
    if n64 < 0 or n64 > Int64(MAX_VERTICES):
        return -1
    let n = Int(n64)
    if values.len() != n + 1:
        return -1
    let domain = (UInt64(1) << n) - UInt64(1)
    var search = Search()
    for vertex in range(n):
        let row = values[1 + vertex]
        if row < 0 or (UInt64(row) & (~domain)) != 0:
            return -1
        search.adjacency[vertex] = UInt64(row)
        if (search.adjacency[vertex] & (UInt64(1) << vertex)) != 0:
            return -1
    for left in range(n):
        for right in range(left + 1, n):
            let forward = (search.adjacency[left] & (UInt64(1) << right)) != 0
            let reverse = (search.adjacency[right] & (UInt64(1) << left)) != 0
            if forward != reverse:
                return -1
    if n == 0:
        return 0
    var vertices = InlineArray[Int, MAX_VERTICES](fill=0)
    for i in range(n):
        vertices[i] = i
    let roots = degree_order(search, vertices, n)
    expand(search, roots, n, 1)
    return Int64(search.best)

@export("konc_maxclique_dyn")
fn konc_maxclique_dyn(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input.is_null() or length < 1 or length > MAX_PARSEABLE_INPUT:
        return -1
    return solve_konc_maxclique_dyn(input[0:length])

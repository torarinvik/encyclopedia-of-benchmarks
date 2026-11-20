from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_VERTICES = 8
comptime MAX_EDGES = 28
comptime MAX_INPUT_LENGTH = 86
comptime MAX_PARSEABLE_LENGTH = 87
comptime ADJACENCY_CELLS = 64

fn louvain_partition_score(adjacency: InlineArray[Int64, ADJACENCY_CELLS],
        community: InlineArray[Int, MAX_VERTICES], n: Int) -> Int64:
    var degree = InlineArray[Int64, MAX_VERTICES](fill=0)
    var total_degree: Int64 = 0
    var internal_directed: Int64 = 0
    for i in range(n):
        for j in range(n):
            let weight = adjacency[i * MAX_VERTICES + j]
            degree[i] += weight
            if community[i] == community[j]:
                internal_directed += weight
        total_degree += degree[i]

    var degree_squares: Int64 = 0
    for i in range(n):
        var first_in_community = True
        for j in range(i):
            if community[j] == community[i]:
                first_in_community = False
                break
        if first_in_community:
            var community_degree: Int64 = 0
            for j in range(i, n):
                if community[j] == community[i]:
                    community_degree += degree[j]
            degree_squares += community_degree * community_degree
    return total_degree * internal_directed - degree_squares

@export("louvain_multilevel_community_detection")
fn louvain_multilevel_community_detection(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or
            length < 5 or length > MAX_PARSEABLE_LENGTH:
        return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 2 or n64 > MAX_VERTICES or m64 < 1 or m64 > MAX_EDGES:
        return -1
    let n_input = Int(n64)
    let m = Int(m64)
    if length != c_size_t(2 + 3 * m) or length > MAX_INPUT_LENGTH:
        return -1

    var adjacency = InlineArray[Int64, ADJACENCY_CELLS](fill=0)
    var vertex_masks = InlineArray[UInt64, MAX_VERTICES](fill=0)
    var canonical_keys = InlineArray[Int, MAX_VERTICES](fill=0)
    for vertex in range(n_input):
        vertex_masks[vertex] = UInt64(1) << vertex
        canonical_keys[vertex] = vertex

    var previous_u: Int64 = -1
    var previous_v: Int64 = -1
    for edge in range(m):
        let u64 = input[2 + 3 * edge]
        let v64 = input[3 + 3 * edge]
        let weight = input[4 + 3 * edge]
        if u64 < 0 or u64 >= v64 or v64 >= n64 or weight < 1 or weight > 7:
            return -1
        if edge > 0 and (u64 < previous_u or (u64 == previous_u and v64 <= previous_v)):
            return -1
        let u = Int(u64)
        let v = Int(v64)
        adjacency[u * MAX_VERTICES + v] = weight
        adjacency[v * MAX_VERTICES + u] = weight
        previous_u = u64
        previous_v = v64

    var n = n_input
    while True:
        var community = InlineArray[Int, MAX_VERTICES](fill=0)
        for vertex in range(n):
            community[vertex] = vertex

        var any_move = False
        while True:
            var sweep_moved = False
            for vertex in range(n):
                let current_score = louvain_partition_score(adjacency, community, n)
                let old_community = community[vertex]
                var best_community = -1
                var best_gain: Int64 = 0
                var best_key = MAX_VERTICES
                for neighbor in range(n):
                    if neighbor != vertex and adjacency[vertex * MAX_VERTICES + neighbor] > 0:
                        let target = community[neighbor]
                        if target != old_community:
                            var seen_before = False
                            for earlier in range(neighbor):
                                if earlier != vertex and adjacency[vertex * MAX_VERTICES + earlier] > 0 and community[earlier] == target:
                                    seen_before = True
                                    break
                            if not seen_before:
                                var target_key = MAX_VERTICES
                                for member in range(n):
                                    if community[member] == target and canonical_keys[member] < target_key:
                                        target_key = canonical_keys[member]
                                community[vertex] = target
                                let candidate_score = louvain_partition_score(adjacency, community, n)
                                community[vertex] = old_community
                                let gain = candidate_score - current_score
                                if gain > 0 and (gain > best_gain or (gain == best_gain and target_key < best_key)):
                                    best_community = target
                                    best_gain = gain
                                    best_key = target_key
                if best_community >= 0:
                    community[vertex] = best_community
                    sweep_moved = True
                    any_move = True
            if not sweep_moved:
                break

        if not any_move:
            break

        var group_label = InlineArray[Int, MAX_VERTICES](fill=0)
        var group_key = InlineArray[Int, MAX_VERTICES](fill=0)
        var group_mask = InlineArray[UInt64, MAX_VERTICES](fill=0)
        var group_of = InlineArray[Int, MAX_VERTICES](fill=0)
        var group_count = 0
        for vertex in range(n):
            var group = 0
            while group < group_count and group_label[group] != community[vertex]:
                group += 1
            if group == group_count:
                group_label[group] = community[vertex]
                group_key[group] = canonical_keys[vertex]
                group_count += 1
            group_of[vertex] = group
            group_mask[group] |= vertex_masks[vertex]
        if group_count >= n:
            return -1

        var next_adjacency = InlineArray[Int64, ADJACENCY_CELLS](fill=0)
        for i in range(n):
            for j in range(n):
                let destination = group_of[i] * MAX_VERTICES + group_of[j]
                next_adjacency[destination] += adjacency[i * MAX_VERTICES + j]
        for index in range(ADJACENCY_CELLS):
            adjacency[index] = next_adjacency[index]
        for group in range(group_count):
            vertex_masks[group] = group_mask[group]
            canonical_keys[group] = group_key[group]
        n = group_count

    var labels = InlineArray[Int64, MAX_VERTICES](fill=0)
    for vertex in range(n):
        for original in range(MAX_VERTICES):
            if (vertex_masks[vertex] & (UInt64(1) << original)) != 0:
                labels[original] = Int64(canonical_keys[vertex])
    var packed = UInt64(n) << 24
    for original in range(MAX_VERTICES):
        packed |= UInt64(labels[original]) << (3 * original)
    return Int64(packed)

package dynamic_centroid_active_set_diameter

import "core:c"

MAX_N :: 32
MAX_OPERATIONS :: 64
MAX_LEVELS :: 6
MAX_PARSEABLE_LENGTH :: 98

Record :: struct { centroid, branch, distance: int }
Context :: struct {
    n: int,
    adjacency: [MAX_N][MAX_N]bool,
    blocked: [MAX_N]bool,
    subtree_size: [MAX_N]int,
    records: [MAX_N][MAX_LEVELS]Record,
    record_count: [MAX_N]int,
}

component_size :: proc "contextless" (ctx: ^Context, vertex, parent: int) -> int {
    total := 1
    for neighbor in 0 .. ctx.n {
        if ctx.adjacency[vertex][neighbor] && neighbor != parent && !ctx.blocked[neighbor] {
            total += component_size(ctx, neighbor, vertex)
        }
    }
    ctx.subtree_size[vertex] = total
    return total
}

choose_centroid :: proc "contextless" (ctx: ^Context, vertex, parent, total: int) -> int {
    for neighbor in 0 .. ctx.n {
        if ctx.adjacency[vertex][neighbor] && neighbor != parent && !ctx.blocked[neighbor]
            && ctx.subtree_size[neighbor] > total / 2 {
            return choose_centroid(ctx, neighbor, vertex, total)
        }
    }
    return vertex
}

record_component :: proc "contextless" (ctx: ^Context, centroid, vertex, parent,
    distance, branch, level: int) {
    if level >= MAX_LEVELS do return
    ctx.records[vertex][level] = Record{
        centroid = centroid,
        branch = if vertex == centroid then ctx.n else branch,
        distance = distance,
    }
    ctx.record_count[vertex] = level + 1
    for neighbor in 0 .. ctx.n {
        if ctx.adjacency[vertex][neighbor] && neighbor != parent && !ctx.blocked[neighbor] {
            next_branch := if vertex == centroid then neighbor else branch
            record_component(ctx, centroid, neighbor, vertex, distance + 1,
                             next_branch, level)
        }
    }
}

build_centroids :: proc "contextless" (ctx: ^Context, entry, level: int) {
    if level >= MAX_LEVELS do return
    total := component_size(ctx, entry, -1)
    centroid := choose_centroid(ctx, entry, -1, total)
    record_component(ctx, centroid, centroid, -1, 0, ctx.n, level)
    ctx.blocked[centroid] = true
    for neighbor in 0 .. ctx.n {
        if ctx.adjacency[centroid][neighbor] && !ctx.blocked[neighbor] {
            build_centroids(ctx, neighbor, level + 1)
        }
    }
}

recompute_branch :: proc "contextless" (ctx: ^Context, active: ^[MAX_N]bool,
    best: ^[MAX_N][MAX_N + 1]int, centroid, branch: int) {
    best^[centroid][branch] = -1
    for vertex in 0 .. ctx.n {
        if !active^[vertex] do continue
        for record_index in 0 .. ctx.record_count[vertex] {
            record := ctx.records[vertex][record_index]
            if record.centroid == centroid && record.branch == branch {
                best^[centroid][branch] = max(best^[centroid][branch], record.distance)
            }
        }
    }
}

active_diameter :: proc "contextless" (n: int, best: ^[MAX_N][MAX_N + 1]int) -> int {
    answer := 0
    for centroid in 0 .. n {
        first, second := -1, -1
        for branch in 0 .. n + 1 {
            distance := best^[centroid][branch]
            if distance > first { second = first; first = distance }
            else if distance > second { second = distance }
        }
        if second >= 0 { answer = max(answer, first + second) }
    }
    return answer
}

@(export)
dynamic_centroid_active_set_diameter :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_PARSEABLE_LENGTH do return -1
    n_value, operation_count_value := input[0], input[1]
    if n_value < 1 || n_value > MAX_N || operation_count_value < 0
        || operation_count_value > MAX_OPERATIONS do return -1
    n, operation_count := int(n_value), int(operation_count_value)
    if length != c.size_t(n + 1 + operation_count) do return -1

    ctx := Context{n = n}
    for vertex in 1 .. n {
        parent_value := input[vertex + 1]
        if parent_value < 0 || parent_value >= i64(vertex) do return -1
        parent := int(parent_value)
        ctx.adjacency[parent][vertex] = true
        ctx.adjacency[vertex][parent] = true
    }
    for offset in 0 .. operation_count {
        operation := input[n + 1 + offset]
        if operation != -1 && (operation < 0 || operation >= i64(n)) do return -1
    }

    build_centroids(&ctx, 0, 0)
    best: [MAX_N][MAX_N + 1]int
    active: [MAX_N]bool
    for centroid in 0 .. n {
        for branch in 0 .. n + 1 { best[centroid][branch] = -1 }
    }
    checksum: i64 = 0
    query_number: i64 = 0
    for offset in 0 .. operation_count {
        operation := input[n + 1 + offset]
        if operation == -1 {
            query_number += 1
            checksum += query_number * i64(active_diameter(n, &best) + 1)
            continue
        }
        vertex := int(operation)
        active[vertex] = !active[vertex]
        for record_index in 0 .. ctx.record_count[vertex] {
            record := ctx.records[vertex][record_index]
            if active[vertex] {
                best[record.centroid][record.branch] = max(
                    best[record.centroid][record.branch], record.distance)
            } else if best[record.centroid][record.branch] == record.distance {
                recompute_branch(&ctx, &active, &best, record.centroid, record.branch)
            }
        }
    }
    return checksum
}

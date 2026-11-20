// Clean-room bounded implementation of Mestre's strict weighted profile.
package mestre_strict_weighted_popular_matching

import "core:c"

A :: 4
J :: 5
N :: 9
PARSEABLE :: 31
INF :: i64(1_000_000_000)

ms_lambda_min :: proc "contextless" (a, target: int, row: [A][N]int,
        row_length: [A]int, f_category: [N]int, label: [N]i64) -> i64 {
    best := INF
    for i := 0; i < row_length[a]; i += 1 {
        job := row[a][i]
        if job == target do break
        if f_category[job] >= 0 && label[job] < best do best = label[job]
    }
    return best
}

ms_augment :: proc "contextless" (a: int, edges: [A][2]int, edge_count: [A]int,
        owner: ^[N]int, seen: ^[N]bool) -> bool {
    for i := 0; i < edge_count[a]; i += 1 {
        job := edges[a][i]
        if seen[job] do continue
        seen[job] = true
        previous := owner[job]
        if previous < 0 || ms_augment(previous, edges, edge_count, owner, seen) {
            owner[job] = a
            return true
        }
    }
    return false
}

ms_solve :: proc "contextless" (applicants, jobs: int, weights: [A]i64,
        lengths: [A]int, listed: [A][J]int) -> i64 {
    row: [A][N]int
    row_length: [A]int
    for a := 0; a < applicants; a += 1 {
        for i := 0; i < lengths[a]; i += 1 {
            row[a][row_length[a]] = listed[a][i]
            row_length[a] += 1
        }
        row[a][row_length[a]] = jobs + a
        row_length[a] += 1
    }
    category_weight: [A]i64
    category_count := 0
    for a := 0; a < applicants; a += 1 {
        found := false
        for cidx := 0; cidx < category_count; cidx += 1 {
            if category_weight[cidx] == weights[a] do found = true
        }
        if !found { category_weight[category_count] = weights[a]; category_count += 1 }
    }
    for i := 0; i < category_count; i += 1 {
        for j := i + 1; j < category_count; j += 1 {
            if category_weight[j] > category_weight[i] {
                category_weight[i], category_weight[j] = category_weight[j], category_weight[i]
            }
        }
    }
    category: [A]int
    for a := 0; a < applicants; a += 1 {
        for category[a] < category_count && category_weight[category[a]] != weights[a] { category[a] += 1 }
    }

    first, second: [A]int
    f_category: [N]int
    label: [N]i64
    higher: [N]bool
    for p := 0; p < N; p += 1 { f_category[p] = -1; label[p] = INF }
    for cidx := 0; cidx < category_count; cidx += 1 {
        for a := 0; a < applicants; a += 1 {
            if category[a] == cidx {
                for i := 0; i < row_length[a]; i += 1 {
                    p := row[a][i]
                    if !higher[p] { first[a] = p; break }
                }
            }
        }
        for a := 0; a < applicants; a += 1 {
            if category[a] == cidx { f_category[first[a]] = cidx; higher[first[a]] = true }
        }
    }
    for a := 0; a < applicants; a += 1 {
        second[a] = -1
        for i := 0; i < row_length[a]; i += 1 {
            p := row[a][i]
            if f_category[p] < 0 || f_category[p] > category[a] { second[a] = p; break }
        }
    }
    keep_first, keep_second: [A]bool
    for a := 0; a < applicants; a += 1 { keep_first[a] = true; keep_second[a] = second[a] >= 0 }
    for cidx := 0; cidx < category_count; cidx += 1 {
        weight := category_weight[cidx]
        if cidx == 0 {
            for a := 0; a < applicants; a += 1 { if category[a] == cidx do label[first[a]] = weight }
            continue
        }
        for a := 0; a < applicants; a += 1 {
            if category[a] == cidx && ms_lambda_min(a, first[a], row, row_length, f_category, label) < weight do return 0
        }
        for p := 0; p < N; p += 1 {
            if f_category[p] == cidx {
                group: [A]int
                count := 0
                for a := 0; a < applicants; a += 1 {
                    if category[a] == cidx && first[a] == p { group[count] = a; count += 1 }
                }
                if count == 1 {
                    earlier := ms_lambda_min(group[0], p, row, row_length, f_category, label)
                    if earlier >= INF { label[p] = weight } else { label[p] = min(weight, earlier-weight) }
                } else {
                    label[p] = weight
                    for i := 0; i < count; i += 1 {
                        a := group[i]
                        if ms_lambda_min(a, p, row, row_length, f_category, label) < 2*weight do keep_first[a] = false
                    }
                }
            }
        }
        for a := 0; a < applicants; a += 1 {
            if category[a] == cidx && second[a] >= 0 && ms_lambda_min(a, second[a], row, row_length, f_category, label) < weight do keep_second[a] = false
        }
    }
    is_first: [N]bool
    for a := 0; a < applicants; a += 1 { is_first[first[a]] = true }
    for p := 0; p < N; p += 1 {
        if is_first[p] {
            eligible := false
            for a := 0; a < applicants; a += 1 { if first[a] == p && keep_first[a] do eligible = true }
            if !eligible do return 0
        }
    }
    edges: [A][2]int
    edge_count: [A]int
    for a := 0; a < applicants; a += 1 {
        if keep_first[a] { edges[a][edge_count[a]] = first[a]; edge_count[a] += 1 }
        if keep_second[a] && second[a] >= 0 && !is_first[second[a]] {
            edges[a][edge_count[a]] = second[a]; edge_count[a] += 1
        }
        if edge_count[a] == 0 do return 0
    }
    owner: [N]int
    for p := 0; p < N; p += 1 { owner[p] = -1 }
    for a := 0; a < applicants; a += 1 {
        seen: [N]bool
        if !ms_augment(a, edges, edge_count, &owner, &seen) do return 0
    }
    return 1
}

mestre_strict_weighted_popular_matching :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(PARSEABLE) do return -1
    a64, j64 := input[0], input[1]
    if a64 < 1 || a64 > A || j64 < 1 || j64 > J do return -1
    applicants, jobs := int(a64), int(j64)
    if length < c.size_t(2 + 2*applicants) do return -1
    weights: [A]i64
    lengths: [A]int
    total := 0
    for a := 0; a < applicants; a += 1 {
        weights[a] = input[2+a]
        size := input[2+applicants+a]
        if weights[a] < 1 || weights[a] > 1000 || size < 1 || size > j64 do return -1
        lengths[a] = int(size); total += lengths[a]
    }
    if length != c.size_t(2 + 2*applicants + total) do return -1
    listed: [A][J]int
    cursor := 2 + 2*applicants
    for a := 0; a < applicants; a += 1 {
        for i := 0; i < lengths[a]; i += 1 {
            value := input[cursor]; cursor += 1
            if value < 0 || value >= j64 do return -1
            p := int(value)
            for k := 0; k < i; k += 1 { if listed[a][k] == p do return -1 }
            listed[a][i] = p
        }
    }
    return ms_solve(applicants, jobs, weights, lengths, listed)
}

package statistical_region_merging_table

import "core:c"

srm_root :: proc(parent: ^[36]int, start: int) -> int {
    x := start
    for parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x] }
    return x
}

@(export)
statistical_region_merging_table :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > 74 do return -1
    if input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 6 do return -1
    width := int(input[1]); n := int(input[0]) * width
    if length != c.size_t(2+2*n) do return -1
    for i := 0; i < n; i += 1 do
        if input[2+i] < 0 || input[2+i] > 65535 || input[2+n+i] < 0 || input[2+n+i] > 255 do return -1
    parent, sizes, minimum: [36]int
    sums: [36]i64
    for i := 0; i < n; i += 1 { parent[i] = i; sizes[i] = 1; minimum[i] = i; sums[i] = input[2+n+i] }
    for diff := 0; diff < 256; diff += 1 {
        for p := 0; p < n; p += 1 {
            neighbors: [2]int; count := 0
            if p % width + 1 < width { neighbors[count] = p+1; count += 1 }
            if p + width < n { neighbors[count] = p+width; count += 1 }
            for k := 0; k < count; k += 1 {
                q := neighbors[k]; d := input[2+n+p] - input[2+n+q]
                if d < 0 do d = -d
                if d != i64(diff) do continue
                a := srm_root(&parent, p); b := srm_root(&parent, q)
                if a == b do continue
                na, nb := i64(sizes[a]), i64(sizes[b])
                delta := sums[a]*nb - sums[b]*na
                bound := input[1+sizes[a]] + input[1+sizes[b]]
                if delta*delta > bound*na*na*nb*nb do continue
                if sizes[a] < sizes[b] { t := a; a = b; b = t }
                parent[b] = a; sizes[a] += sizes[b]; sums[a] += sums[b]
                if minimum[b] < minimum[a] do minimum[a] = minimum[b]
            }
        }
    }
    if output == nil || capacity < c.size_t(n) do return -2
    for i := 0; i < n; i += 1 do output[i] = u8(minimum[srm_root(&parent, i)])
    return i64(n)
}

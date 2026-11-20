module undirected_eulerian_trail_hierholzer

@[export: 'undirected_eulerian_trail_hierholzer']
pub fn undirected_eulerian_trail_hierholzer(input &i64, length usize, output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 2 || length > 67 { return -1 }
    unsafe {
        if input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 32 { return -1 }
        n := int(input[0]); m := int(input[1])
        if int(length) != 2 + 2 * m { return -1 }
        mut endpoints := [32][2]int{}
        mut adjacency := [16][64]int{}
        mut degree := [16]int{}
        mut cursor := [16]int{}
        for e in 0 .. m {
            u0 := input[2 + 2 * e]; v0 := input[3 + 2 * e]
            if u0 < 0 || v0 < 0 || u0 >= i64(n) || v0 >= i64(n) { return -1 }
            u := int(u0); v := int(v0)
            endpoints[e][0] = u; endpoints[e][1] = v
            adjacency[u][degree[u]] = e; degree[u]++
            adjacency[v][degree[v]] = e; degree[v]++
        }
        mut odd := 0; mut start := 0
        for v in 0 .. n {
            if degree[v] % 2 != 0 {
                if odd == 0 { start = v }
                odd++
            }
        }
        if odd != 0 && odd != 2 { return 0 }
        if odd == 0 && m != 0 { for degree[start] == 0 { start++ } }
        mut used := [32]bool{}
        mut stack := [33]int{}
        mut reverse := [33]int{}
        mut top := 1; mut count := 0; stack[0] = start
        for top != 0 {
            v := stack[top - 1]
            for cursor[v] < degree[v] && used[adjacency[v][cursor[v]]] { cursor[v]++ }
            if cursor[v] == degree[v] { top--; reverse[count] = stack[top]; count++ }
            else {
                e := adjacency[v][cursor[v]]; cursor[v]++; used[e] = true
                stack[top] = if endpoints[e][0] == v { endpoints[e][1] } else { endpoints[e][0] }
                top++
            }
        }
        if count != m + 1 { return 0 }
        bytes := count * 8
        if output == nil || capacity < usize(bytes) { return -2 }
        for i in 0 .. count {
            value := u64(reverse[count - 1 - i])
            for b in 0 .. 8 { output[8 * i + b] = u8((value >> (8 * b)) & 255) }
        }
        return i64(bytes)
    }
}

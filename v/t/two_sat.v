module two_sat

fn visit_order(graph &u8, n int, vertex int, mut seen []u8, mut order []int, count int) int {
    mut current := count
    seen[vertex] = 1
    for w in 0 .. n {
        if unsafe { graph[vertex * 80 + w] != 0 } && seen[w] == 0 {
            current = visit_order(graph, n, w, mut seen, mut order, current)
        }
    }
    order[current] = vertex
    return current + 1
}
fn visit_component(graph &u8, n int, vertex int, mut component []int, id int) {
    component[vertex] = id
    for w in 0 .. n {
        if unsafe { graph[vertex * 80 + w] != 0 } && component[w] < 0 {
            visit_component(graph, n, w, mut component, id)
        }
    }
}

@[export: 'two_sat']
fn two_sat(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 2 || length > 4096 { return -1 }
    unsafe {
        if input[0] < 0 || input[0] > 40 || input[1] < 0 || input[1] > 2047 { return -1 }
        variables := int(input[0]); clauses := int(input[1])
        if length != usize(2 + 2 * clauses) { return -1 }
        n := 2 * variables
        mut graph := []u8{len: 6400, init: 0}
        mut transpose := []u8{len: 6400, init: 0}
        for i in 0 .. clauses {
            a := input[2 + 2 * i]; b := input[3 + 2 * i]
            if a == 0 || b == 0 || a < -i64(variables) || a > i64(variables) || b < -i64(variables) || b > i64(variables) { return -1 }
            aa := int(if a < 0 { -a } else { a }); bb := int(if b < 0 { -b } else { b })
            x := 2 * (aa - 1) + int(a < 0); y := 2 * (bb - 1) + int(b < 0)
            u1 := x ^ 1; u2 := y ^ 1
            graph[u1 * 80 + y] = 1; transpose[y * 80 + u1] = 1
            graph[u2 * 80 + x] = 1; transpose[x * 80 + u2] = 1
        }
        mut seen := []u8{len: 80, init: 0}
        mut order := []int{len: 80, init: 0}
        mut count := 0
        for v in 0 .. n {
            if seen[v] == 0 { count = visit_order(&graph[0], n, v, mut seen, mut order, count) }
        }
        mut component := []int{len: 80, init: -1}
        mut id := 0
        for count > 0 {
            count--
            v := order[count]
            if component[v] < 0 { visit_component(&transpose[0], n, v, mut component, id); id++ }
        }
        mut satisfiable := true
        for i in 0 .. variables { if component[2 * i] == component[2 * i + 1] { satisfiable = false } }
        outlen := usize(1)
        if satisfiable { outlen = usize(variables + 1) }
        if output == nil || capacity < outlen { return -2 }
        output[0] = u8(int(satisfiable))
        if satisfiable {
            for i in 0 .. variables { output[i + 1] = u8(int(component[2 * i] > component[2 * i + 1])) }
        }
        return i64(outlen)
    }
}

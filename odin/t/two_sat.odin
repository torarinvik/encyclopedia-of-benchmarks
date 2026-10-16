package two_sat
import "core:c"

Max_Lits :: 80
visit_order :: proc "contextless" (graph: [^]u8, n, v: int, seen: [^]u8, order: [^]int, count: ^int) {
    seen[v] = 1
    for w := 0; w < n; w += 1 { if graph[v*Max_Lits+w] != 0 && seen[w] == 0 do visit_order(graph,n,w,seen,order,count) }
    order[count^] = v; count^ += 1
}
visit_component :: proc "contextless" (graph: [^]u8, n, v: int, comp: [^]int, id: int) {
    comp[v] = id
    for w := 0; w < n; w += 1 { if graph[v*Max_Lits+w] != 0 && comp[w] < 0 do visit_component(graph,n,w,comp,id) }
}
@(export)
two_sat :: proc "c" (input: [^]i64, length: uint, output: [^]u8, capacity: uint) -> i64 {
    if input == nil || length < 2 || length > 4096 do return -1
    if input[0] < 0 || input[0] > 40 || input[1] < 0 || input[1] > 2047 do return -1
    variables := int(input[0]); clauses := int(input[1])
    if length != uint(2+2*clauses) do return -1
    n := variables*2
    graph: [6400]u8; transpose: [6400]u8
    for i := 0; i < 6400; i += 1 { graph[i] = 0; transpose[i] = 0 }
    for i := 0; i < clauses; i += 1 {
        a := input[2+2*i]; b := input[3+2*i]
        if a == 0 || b == 0 || a < -i64(variables) || a > i64(variables) || b < -i64(variables) || b > i64(variables) do return -1
        aa := int(a); if aa < 0 do aa = -aa
        bb := int(b); if bb < 0 do bb = -bb
        x := 2*(aa-1); if a < 0 do x += 1
        y := 2*(bb-1); if b < 0 do y += 1
        u1 := x ~ 1; u2 := y ~ 1
        graph[u1*Max_Lits+y] = 1; transpose[y*Max_Lits+u1] = 1
        graph[u2*Max_Lits+x] = 1; transpose[x*Max_Lits+u2] = 1
    }
    seen: [80]u8; order: [80]int; count := 0
    for i := 0; i < 80; i += 1 { seen[i] = 0; order[i] = 0 }
    for v := 0; v < n; v += 1 { if seen[v] == 0 do visit_order(&graph[0],n,v,&seen[0],&order[0],&count) }
    comp: [80]int
    for i := 0; i < n; i += 1 { comp[i] = -1 }
    id := 0
    for count > 0 { count -= 1; v := order[count]; if comp[v] < 0 { visit_component(&transpose[0],n,v,&comp[0],id); id += 1 } }
    sat := true
    for i := 0; i < variables; i += 1 { if comp[2*i] == comp[2*i+1] do sat = false }
    outlen := uint(1); if sat do outlen = uint(variables+1)
    if output == nil || capacity < outlen do return -2
    output[0] = 0; if sat do output[0] = 1
    if sat { for i := 0; i < variables; i += 1 { output[i+1] = 0; if comp[2*i] > comp[2*i+1] do output[i+1] = 1 } }
    return i64(outlen)
}

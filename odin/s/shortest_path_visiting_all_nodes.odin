package shortest_path_visiting_all_nodes
import "core:c"

MAX_N :: 10
MAX_STATES :: 10240
MAX_PARSEABLE_LENGTH :: 93

@(export)
shortest_path_visiting_all_nodes :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_PARSEABLE_LENGTH do return -1
    n_value := input[0]
    m_value := input[1]
    if n_value < 1 || n_value > MAX_N || m_value < 0 || m_value > 45 do return -1
    n := int(n_value)
    m := int(m_value)
    if m > n*(n-1)/2 || length != c.size_t(2+2*m) do return -1

    adjacency: [MAX_N]u16
    for edge:=0; edge<m; edge+=1 {
        u_value := input[2+2*edge]
        v_value := input[3+2*edge]
        if u_value<0 || v_value<0 || u_value>=n_value || v_value>=n_value || u_value==v_value do return -1
        u := int(u_value)
        v := int(v_value)
        u_bit := u16(1)<<u16(v)
        v_bit := u16(1)<<u16(u)
        if (adjacency[u]&u_bit)!=0 do return -1
        adjacency[u] |= u_bit
        adjacency[v] |= v_bit
    }

    reached: u16 = 1
    for {
        previous := reached
        for vertex:=0; vertex<n; vertex+=1 {
            if (reached&(u16(1)<<u16(vertex)))!=0 do reached |= adjacency[vertex]
        }
        if reached==previous do break
    }
    full := (u16(1)<<u16(n))-1
    if reached!=full do return -1

    state_count := (1<<n)*n
    distance: [MAX_STATES]i16
    queue: [MAX_STATES]u16
    for i:=0; i<state_count; i+=1 { distance[i]=-1 }
    head, tail := 0, 0
    for start:=0; start<n; start+=1 {
        state := (1<<start)*n+start
        distance[state]=0
        queue[tail]=u16(state)
        tail+=1
    }
    for head<tail {
        state := int(queue[head])
        head+=1
        mask := state/n
        vertex := state%n
        if mask==int(full) do return i64(distance[state])
        for next:=0; next<n; next+=1 {
            if (adjacency[vertex]&(u16(1)<<u16(next)))==0 do continue
            next_mask := mask|(1<<next)
            next_state := next_mask*n+next
            if distance[next_state]>=0 do continue
            distance[next_state]=distance[state]+1
            queue[tail]=u16(next_state)
            tail+=1
        }
    }
    return -1
}

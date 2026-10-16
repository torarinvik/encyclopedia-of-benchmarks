package hamiltonian_path_exists
import "core:c"
MAX_VERTICES :: 8
MAX_STATES :: 256
MAX_INPUT_LENGTH :: 65
@(export)
hamiltonian_path_exists :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > MAX_INPUT_LENGTH || input[0] < 0 || input[0] > MAX_VERTICES do return -1
    n := int(input[0])
    if length != c.size_t(1+n*n) do return -1
    routes: [MAX_VERTICES]u64
    for row:=0; row<n; row+=1 {
        for col:=0; col<n; col+=1 {
            cell:=input[1+row*n+col]
            if cell!=0 && cell!=1 do return -1
            if cell==1 do routes[row] |= u64(1)<<u64(col)
        }
    }
    dp: [MAX_STATES*MAX_VERTICES]bool
    for start:=0; start<n; start+=1 { dp[int(u64(1)<<u64(start))*MAX_VERTICES+start]=true }
    state_count:=int(u64(1)<<u64(n))
    full:=state_count-1
    for subset:=1; subset<state_count; subset+=1 {
        for last:=0; last<n; last+=1 {
            if !dp[subset*MAX_VERTICES+last] do continue
            for next:=0; next<n; next+=1 {
                bit:=int(u64(1)<<u64(next))
                if (subset&bit)==0 && (routes[last]&u64(bit))!=0 do dp[(subset|bit)*MAX_VERTICES+next]=true
            }
        }
    }
    for last:=0; last<n; last+=1 { if dp[full*MAX_VERTICES+last] do return 1 }
    return 0
}

package brzozowski_dfa_minimization
import "core:c"

@(export)
brzozowski_dfa_minimization :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 10 do return -1
    n64, start64, accepting64 := input[0], input[1], input[2]
    if n64 < 1 || n64 > 3 || start64 < 0 || start64 >= n64 do return -1
    if accepting64 < 0 || accepting64 >= (1L << n64) do return -1
    n := int(n64)
    if length != c.size_t(3+2*n) do return -1
    start := int(start64)

    transitions: [3][2]int
    for state:=0; state<n; state+=1 {
        for symbol:=0; symbol<2; symbol+=1 {
            target:=input[3+2*state+symbol]
            if target<0 || target>=n64 do return -1
            transitions[state][symbol]=int(target)
        }
    }

    first_masks: [8]i64
    first_delta: [8][2]int
    first_final: [8]bool
    first_id: [8]int{-1,-1,-1,-1,-1,-1,-1,-1}
    first_count:=1
    first_masks[0]=accepting64
    first_id[int(accepting64)]=0
    for cursor:=0; cursor<first_count; cursor+=1 {
        subset:=first_masks[cursor]
        first_final[cursor]=((subset>>start)&1)!=0
        for symbol:=0; symbol<2; symbol+=1 {
            predecessor:i64=0
            for state:=0; state<n; state+=1 {
                if (subset&(1L<<transitions[state][symbol]))!=0 {
                    predecessor|=1L<<state
                }
            }
            mask_index:=int(predecessor)
            if first_id[mask_index]<0 {
                first_id[mask_index]=first_count
                first_masks[first_count]=predecessor
                first_count+=1
            }
            first_delta[cursor][symbol]=first_id[mask_index]
        }
    }
    first_accepting:i64=0
    for state:=0; state<first_count; state+=1 {
        if first_final[state] do first_accepting|=1L<<state
    }

    second_queue: [256]i64
    second_seen: [256]bool
    second_count:=1
    second_queue[0]=first_accepting
    second_seen[int(first_accepting)]=true
    for cursor:=0; cursor<second_count; cursor+=1 {
        subset:=second_queue[cursor]
        for symbol:=0; symbol<2; symbol+=1 {
            predecessor:i64=0
            for state:=0; state<first_count; state+=1 {
                if (subset&(1L<<first_delta[state][symbol]))!=0 {
                    predecessor|=1L<<state
                }
            }
            mask_index:=int(predecessor)
            if !second_seen[mask_index] {
                second_seen[mask_index]=true
                second_queue[second_count]=predecessor
                second_count+=1
            }
        }
    }
    return i64(second_count)
}

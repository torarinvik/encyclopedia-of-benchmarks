package moore_dfa_minimization

import "core:c"

@(export)
moore_dfa_minimization :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 4 || length > 29 do return -1
    n64, alphabet64, start64, accepting := input[0], input[1], input[2], input[3]
    if n64 < 1 || n64 > 8 || alphabet64 < 1 || alphabet64 > 3 do return -1
    if start64 < 0 || start64 >= n64 || accepting < 0 || accepting >= (1L << n64) do return -1
    n, alphabet := int(n64), int(alphabet64)
    if length != c.size_t(4+n*alphabet) do return -1

    transitions: [8][3]int
    for state:=0; state<n; state+=1 {
        for symbol:=0; symbol<alphabet; symbol+=1 {
            target:=input[4+state*alphabet+symbol]
            if target<0 || target>=n64 do return -1
            transitions[state][symbol]=int(target)
        }
    }
    labels: [8]int
    refined: [8]int
    acceptance_id: [2]int{-1,-1}
    classes:=0
    for state:=0; state<n; state+=1 {
        bit:=int((accepting>>state)&1)
        if acceptance_id[bit]<0 {
            acceptance_id[bit]=classes
            classes+=1
        }
        labels[state]=acceptance_id[bit]
    }
    rounds:=0
    for {
        signatures: [8]int
        signature_count:=0
        for state:=0; state<n; state+=1 {
            signature:=labels[state]
            for symbol:=0; symbol<alphabet; symbol+=1 {
                signature=signature*8+labels[transitions[state][symbol]]
            }
            id:=0
            for id<signature_count && signatures[id]!=signature { id+=1 }
            if id==signature_count {
                signatures[signature_count]=signature
                signature_count+=1
            }
            refined[state]=id
        }
        changed:=false
        for state:=0; state<n; state+=1 { if refined[state]!=labels[state] { changed=true } }
        if !changed {
            classes=signature_count
            break
        }
        for state:=0; state<n; state+=1 { labels[state]=refined[state] }
        classes=signature_count
        rounds+=1
    }
    packed:i64=(i64(classes)<<28)|(i64(rounds)<<24)
    for state:=0; state<n; state+=1 { packed|=i64(labels[state])<<(3*state) }
    return packed
}

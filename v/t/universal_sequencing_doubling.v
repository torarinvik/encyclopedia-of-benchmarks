module universal_sequencing_doubling
const max_n=12
const max_weight=32
const max_levels=6
const max_input=25
const max_output=104

fn put_i64(mut output &u8, offset int, value i64) {
    bits:=u64(value)
    for byte in 0..8 { unsafe { output[offset+byte]=u8((bits>>(8*byte))&255) } }
}

@[export:'universal_sequencing_doubling']
pub fn universal_sequencing_doubling(input &i64, length usize, mut output &u8, capacity usize) i64 { unsafe {
    if input==nil || length<3 || length>max_input || input[0]<1 || input[0]>max_n || length!=usize(1+2*input[0]) { return -1 }
    n:=int(input[0]); mut processing:=[max_n]i64{}; mut weights:=[max_n]int{}; mut total:=0
    for job in 0..n {
        p,w:=input[1+2*job],input[2+2*job]
        if p<1 || p>255 || w<1 || w>max_weight { return -1 }
        processing[job]=p; weights[job]=int(w); total+=int(w)
    }
    if total>max_weight || (total&(total-1))!=0 { return -1 }
    mut level_sets:=[max_levels]u16{}; mut levels:=0; mut bound:=1
    for bound<=total {
        mut best:=[max_weight+1]i64{}; mut masks:=[max_weight+1]u16{}; mut reachable:=[max_weight+1]bool{}; reachable[0]=true
        for job in 0..n {
            mut used:=bound
            for used>=weights[job] {
                if reachable[used-weights[job]] {
                    candidate:=best[used-weights[job]]+processing[job]
                    candidate_mask:=masks[used-weights[job]]|(u16(1)<<u16(job))
                    if !reachable[used] || candidate>best[used] || (candidate==best[used] && candidate_mask<masks[used]) {
                        reachable[used]=true; best[used]=candidate; masks[used]=candidate_mask
                    }
                }
                used--
            }
        }
        mut maximum:=i64(-1); mut selected:=u16(0)
        for used in 0..bound+1 {
            if reachable[used] && (best[used]>maximum || (best[used]==maximum && masks[used]<selected)) { maximum=best[used]; selected=masks[used] }
        }
        level_sets[levels]=selected; levels++; bound*=2
    }
    mut rank:=[max_n]int{}
    for job in 0..n {
        rank[job]=-1
        for level in 0..levels { if (level_sets[level]&(u16(1)<<u16(job)))!=0 { rank[job]=level; break } }
        if rank[job]<0 { return -1 }
    }
    mut words:=[max_n+1]i64{}; words[0]=i64(n); mut count:=1
    for level in 0..levels { actual:=levels-1-level; for job in 0..n { if rank[job]==actual { words[count]=i64(job); count++ } } }
    bytes:=8*count
    if output==nil || capacity<usize(bytes) { return -2 }
    mut staged:=[max_output]u8{}
    for i in 0..count { put_i64(mut &staged[0],8*i,words[i]) }
    for i in 0..bytes { output[i]=staged[i] }
    return i64(bytes)
} }

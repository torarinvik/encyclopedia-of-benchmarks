package universal_sequencing_doubling
import "core:c"

N :: 12
MAX_WEIGHT :: 32
MAX_LEVELS :: 6
MAX_INPUT :: 25
MAX_OUTPUT :: 104

put_i64 :: proc(out:[^]u8, offset:int, value:i64) {
    bits := u64(value)
    for byte:=0; byte<8; byte+=1 { out[offset+byte]=u8(bits&255); bits>>=8 }
}

@(export)
universal_sequencing_doubling :: proc "c" (input:[^]i64, length:c.size_t, output:[^]u8, capacity:c.size_t)->i64 {
    if input==nil || length<3 || length>MAX_INPUT || input[0]<1 || input[0]>N || length!=c.size_t(1+2*input[0]) { return -1 }
    n:=int(input[0]); p:[N]i64; w:[N]int; total:=0
    for j:=0; j<n; j+=1 {
        if input[1+2*j]<1 || input[1+2*j]>255 || input[2+2*j]<1 || input[2+2*j]>MAX_WEIGHT { return -1 }
        p[j]=input[1+2*j]; w[j]=int(input[2+2*j]); total+=w[j]
    }
    if total>MAX_WEIGHT || (total&(total-1))!=0 { return -1 }
    sets:[MAX_LEVELS]u16; levels:=0; bound:=1
    for bound<=total {
        best:[MAX_WEIGHT+1]i64; masks:[MAX_WEIGHT+1]u16; reachable:[MAX_WEIGHT+1]bool; reachable[0]=true
        for j:=0; j<n; j+=1 {
            for used:=bound; used>=w[j]; used-=1 {
                if !reachable[used-w[j]] { continue }
                candidate:=best[used-w[j]]+p[j]; candidate_mask:=masks[used-w[j]]|(u16(1)<<u16(j))
                if !reachable[used] || candidate>best[used] || (candidate==best[used] && candidate_mask<masks[used]) {
                    reachable[used]=true; best[used]=candidate; masks[used]=candidate_mask
                }
            }
        }
        maximum:i64=-1; selected:u16=0
        for used:=0; used<=bound; used+=1 {
            if reachable[used] && (best[used]>maximum || (best[used]==maximum && masks[used]<selected)) { maximum=best[used]; selected=masks[used] }
        }
        sets[levels]=selected; levels+=1; bound*=2
    }
    rank:[N]int
    for j:=0; j<n; j+=1 {
        rank[j]=-1
        for level:=0; level<levels; level+=1 { if (sets[level]&(u16(1)<<u16(j)))!=0 { rank[j]=level; break } }
        if rank[j]<0 { return -1 }
    }
    words:[N+1]i64; words[0]=i64(n); count:=1
    for level:=levels-1; level>=0; level-=1 { for j:=0; j<n; j+=1 { if rank[j]==level { words[count]=i64(j); count+=1 } } }
    bytes:=8*count
    if output==nil || capacity<c.size_t(bytes) { return -2 }
    staged:[MAX_OUTPUT]u8
    for i:=0; i<count; i+=1 { put_i64(&staged[0],8*i,words[i]) }
    for i:=0; i<bytes; i+=1 { output[i]=staged[i] }
    return i64(bytes)
}

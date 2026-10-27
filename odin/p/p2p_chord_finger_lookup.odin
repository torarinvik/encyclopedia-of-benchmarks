package p2p_chord_finger_lookup
import "core:c"

MAX_NODES :: 16
MAX_BITS :: 6
MAX_INPUT :: 116
MAX_OUTPUT :: 128
put_i64 :: proc(out: [^]u8, at: int, value: i64) { bits:=u64(value); for i:=0;i<8;i+=1 { out[at+i]=u8(bits&255); bits>>=8 } }

@(export)
p2p_chord_finger_lookup :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input==nil || length<4 || length>MAX_INPUT { return -1 }
    if input[0]<1 || input[0]>MAX_BITS || input[1]<2 || input[1]>MAX_NODES { return -1 }
    bits,n:=int(input[0]),int(input[1]); ring:=1<<bits
    if n>ring || input[2]<0 || input[2]>=i64(n) || input[3]<0 || input[3]>=i64(ring) { return -1 }
    if length!=c.size_t(4+n+n*bits) { return -1 }
    ids:[MAX_NODES]int
    fingers:[MAX_NODES*MAX_BITS]int
    for i:=0;i<n;i+=1 {
        raw:=input[4+i]
        if raw<0 || raw>=i64(ring) || (i>0 && raw<=i64(ids[i-1])) { return -1 }
        ids[i]=int(raw)
    }
    for node:=0;node<n;node+=1 { for level:=0;level<bits;level+=1 {
        target:=(ids[node]+(1<<level))%ring
        successor:=0;for successor<n && ids[successor]<target { successor+=1 };if successor==n { successor=0 }
        raw:=input[4+n+node*bits+level]
        if raw<0 || raw>=i64(n) || int(raw)!=successor { return -1 }
        fingers[node*bits+level]=successor
    } }
    key:=int(input[3]);owner:=0;for owner<n && ids[owner]<key { owner+=1 };if owner==n { owner=0 }
    route:[MAX_NODES]int;route[0]=int(input[2]);route_len:=1;current:=route[0]
    for step:=0;step<n && current!=owner;step+=1 {
        target_distance:=(ids[owner]-ids[current]+ring)%ring;chosen:=-1
        for level:=bits-1;level>=0;level-=1 {
            candidate:=fingers[current*bits+level];progress:=(ids[candidate]-ids[current]+ring)%ring
            if progress>0 && progress<=target_distance { chosen=candidate;break }
        }
        if chosen<0 || route_len>=n { return -1 }
        for j:=0;j<route_len;j+=1 { if route[j]==chosen { return -1 } }
        current=chosen;route[route_len]=current;route_len+=1
    }
    if current!=owner { return -1 }
    bytes:=8*route_len;if output==nil || capacity<c.size_t(bytes) { return -2 }
    staged:[MAX_OUTPUT]u8
    for i:=0;i<route_len;i+=1 { put_i64(&staged[0],8*i,i64(ids[route[i]])) }
    for i:=0;i<bytes;i+=1 { output[i]=staged[i] }
    return i64(bytes)
}

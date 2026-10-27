package sequential_lut_k_cut_enumeration

import "core:c"

MAX_N :: 3
MAX_M :: 3
MAX_CUTS :: 45

put_i64 :: proc "contextless" (output: [^]u8, word: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[word*8+byte] = u8((bits >> (byte*8)) & 255) }
}
popcount :: proc "contextless" (value: u64) -> int {
    bits := value; count := 0
    for bits != 0 { bits &= bits-1; count += 1 }
    return count
}
shift_cut :: proc "contextless" (cut: u64, n, delay: int, result: ^u64) -> bool {
    result^ = 0
    for bit := 0; bit < 3*n; bit += 1 {
        if cut & (u64(1) << bit) != 0 {
            node := bit/3; next_delay := bit%3+delay
            if next_delay > 2 do return false
            result^ |= u64(1) << (3*node+next_delay)
        }
    }
    return true
}
add_cut :: proc "contextless" (cuts: ^[MAX_N][MAX_CUTS]u64, counts: ^[MAX_N]int,
        node: int, mask: u64, k: int) {
    if popcount(mask)>k do return
    for i := 0; i<counts[node]; i+=1 { if cuts[node][i]==mask do return }
    if counts[node]<MAX_CUTS { cuts[node][counts[node]]=mask; counts[node]+=1 }
}

@(export)
sequential_lut_k_cut_enumeration :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input==nil || input_length<3 || input_length>12 do return -1
    n0,k0,m0:=input[0],input[1],input[2]
    if n0<1 || n0>3 || k0<1 || k0>2 || m0<0 || m0>3 || input_length!=c.size_t(3+3*m0) do return -1
    n,k,m:=int(n0),int(k0),int(m0)
    eu,ev,ed: [MAX_M]int
    for e:=0; e<m; e+=1 {
        u,v,d:=input[3+3*e],input[4+3*e],input[5+3*e]
        if u<0 || v<=u || v>=n0 || (d!=0 && d!=1) do return -1
        for j:=0; j<e; j+=1 { if eu[j]==int(u) && ev[j]==int(v) && ed[j]==int(d) do return -1 }
        eu[e],ev[e],ed[e]=int(u),int(v),int(d)
    }
    in_u,in_d: [MAX_N][MAX_M]int
    degree: [MAX_N]int
    for e:=0; e<m; e+=1 { v:=ev[e]; slot:=degree[v]; in_u[v][slot]=eu[e];in_d[v][slot]=ed[e];degree[v]+=1 }
    cuts: [MAX_N][MAX_CUTS]u64
    counts: [MAX_N]int
    for v:=0; v<n; v+=1 {
        add_cut(&cuts,&counts,v,u64(1)<<(3*v),k)
        if degree[v]>0 {
            c0:=counts[in_u[v][0]]; c1,c2:=1,1
            if degree[v]>1 { c1=counts[in_u[v][1]] }; if degree[v]>2 { c2=counts[in_u[v][2]] }
            for a:=0; a<c0; a+=1 { for b:=0; b<c1; b+=1 { for cc:=0; cc<c2; cc+=1 {
                shifted:u64; if !shift_cut(cuts[in_u[v][0]][a],n,in_d[v][0],&shifted) do return -1
                merged:=shifted
                if degree[v]>1 { if !shift_cut(cuts[in_u[v][1]][b],n,in_d[v][1],&shifted) do return -1; merged|=shifted }
                if degree[v]>2 { if !shift_cut(cuts[in_u[v][2]][cc],n,in_d[v][2],&shifted) do return -1; merged|=shifted }
                add_cut(&cuts,&counts,v,merged,k)
            }}}
        }
        for i:=1; i<counts[v]; i+=1 { x:=cuts[v][i];j:=i;for j>0 && cuts[v][j-1]>x { cuts[v][j]=cuts[v][j-1];j-=1 };cuts[v][j]=x }
    }
    words:=1;for v:=0;v<n;v+=1 { words+=1+counts[v] };bytes:=words*8
    if output==nil || output_capacity<c.size_t(bytes) do return -2
    put_i64(output,0,i64(n));at:=1
    for v:=0;v<n;v+=1 { put_i64(output,at,i64(counts[v]));at+=1;for i:=0;i<counts[v];i+=1 { put_i64(output,at,i64(cuts[v][i]));at+=1 } }
    return i64(bytes)
}

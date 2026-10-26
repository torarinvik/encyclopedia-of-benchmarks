package treewidth_min_degree_elimination
import "core:c"

MAX_N :: 16
MAX_EDGES :: 120
MAX_INPUT :: 242
MAX_OUTPUT :: 2064

put_i64 :: proc(out:[^]u8,offset:int,value:i64) {
    bits:=u64(value)
    for byte:=0;byte<8;byte+=1 { out[offset+byte]=u8(bits&255);bits>>=8 }
}

@(export)
treewidth_min_degree_elimination :: proc "c" (
    input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil||length<2||length>MAX_INPUT||input[0]<1||input[0]>MAX_N||input[1]<0||input[1]>MAX_EDGES { return -1 }
    n,m:=int(input[0]),int(input[1])
    if m>n*(n-1)/2||length!=c.size_t(2+2*m) { return -1 }
    adjacent:[MAX_N][MAX_N]bool
    for edge:=0;edge<m;edge+=1 {
        a64,b64:=input[2+2*edge],input[3+2*edge]
        if a64<0||b64<0||a64>=i64(n)||b64>=i64(n)||a64>=b64 { return -1 }
        a,b:=int(a64),int(b64)
        if adjacent[a][b] { return -1 }
        adjacent[a][b]=true;adjacent[b][a]=true
    }
    active:[MAX_N]bool
    order:[MAX_N]i64
    fill_u:[MAX_EDGES]i64
    fill_v:[MAX_EDGES]i64
    for i:=0;i<n;i+=1 { active[i]=true }
    width:=0;fill_count:=0
    for step:=0;step<n;step+=1 {
        chosen:=-1;chosen_degree:=MAX_N+1
        for vertex:=0;vertex<n;vertex+=1 {
            if active[vertex] {
                degree:=0
                for other:=0;other<n;other+=1 { if active[other]&&adjacent[vertex][other] { degree+=1 } }
                if degree<chosen_degree { chosen=vertex;chosen_degree=degree }
            }
        }
        order[step]=i64(chosen)
        if chosen_degree>width { width=chosen_degree }
        neighbors:[MAX_N]int
        neighbor_count:=0
        for other:=0;other<n;other+=1 { if active[other]&&adjacent[chosen][other] { neighbors[neighbor_count]=other;neighbor_count+=1 } }
        for i:=0;i<neighbor_count;i+=1 { for j:=i+1;j<neighbor_count;j+=1 {
            a,b:=neighbors[i],neighbors[j]
            if !adjacent[a][b] { adjacent[a][b]=true;adjacent[b][a]=true;fill_u[fill_count]=i64(a);fill_v[fill_count]=i64(b);fill_count+=1 }
        } }
        active[chosen]=false
    }
    bytes:=8*(n+2+2*fill_count)
    if output==nil||capacity<c.size_t(bytes)||bytes>MAX_OUTPUT { return -2 }
    staged:[MAX_OUTPUT]u8
    put_i64(&staged[0],0,i64(width))
    for i:=0;i<n;i+=1 { put_i64(&staged[0],8*(i+1),order[i]) }
    put_i64(&staged[0],8*(n+1),i64(fill_count))
    for i:=0;i<fill_count;i+=1 { put_i64(&staged[0],8*(n+2+2*i),fill_u[i]);put_i64(&staged[0],8*(n+3+2*i),fill_v[i]) }
    for i:=0;i<bytes;i+=1 { output[i]=staged[i] }
    return i64(bytes)
}

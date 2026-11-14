package highest_label_push_relabel
import "core:c"

@(export)
highest_label_push_relabel :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input==nil || length<4 || length>197 do return -1
    nv,mv,sv,tv:=input[0],input[1],input[2],input[3]
    if nv<2 || nv>16 || mv<0 || mv>64 || sv<1 || sv>nv || tv<1 || tv>nv || sv==tv do return -1
    n,m,source,sink:=int(nv),int(mv),int(sv-1),int(tv-1)
    if length!=c.size_t(4+3*m) do return -1
    residual: [256]i64 = {}; excess: [16]i64 = {}; height: [16]int = {}
    for i:=0; i<m; i+=1 {
        u,v,capacity:=input[4+3*i],input[5+3*i],input[6+3*i]
        if u<1 || u>nv || v<1 || v>nv || u==v || capacity<0 || capacity>100 do return -1
        residual[16*int(u-1)+int(v-1)]+=capacity
    }
    height[source]=n
    for v:=0; v<n; v+=1 {
        amount:=residual[16*source+v]; residual[16*source+v]=0
        residual[16*v+source]+=amount; excess[v]+=amount; excess[source]-=amount
    }
    for {
        active:=-1
        for v:=0; v<n; v+=1 {
            if v!=source && v!=sink && excess[v]>0 && (active<0 || height[v]>height[active]) { active=v }
        }
        if active<0 do return excess[sink]
        destination:=-1; minimum:=2*n+1
        for v:=0; v<n; v+=1 {
            if residual[16*active+v]>0 {
                if height[v]<minimum { minimum=height[v] }
                if destination<0 && height[active]==height[v]+1 { destination=v }
            }
        }
        if destination<0 {
            if minimum>2*n do return -1
            height[active]=minimum+1
        } else {
            amount:=min(excess[active],residual[16*active+destination])
            residual[16*active+destination]-=amount; residual[16*destination+active]+=amount
            excess[active]-=amount; excess[destination]+=amount
        }
    }
}

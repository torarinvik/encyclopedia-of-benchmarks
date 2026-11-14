package dinic_capacity_scaling
import "core:c"

send :: proc(u, sink: int, amount: i64, residual: ^[256]i64, level: ^[16]int,
             cursor: ^[16]int, n: int, threshold: i64) -> i64 {
    if u==sink do return amount
    for cursor[u]<n {
        v:=cursor[u]; edge:=16*u+v
        if level[v]==level[u]+1 && residual[edge]>=threshold {
            pushed:=send(v,sink,min(amount,residual[edge]),residual,level,cursor,n,threshold)
            if pushed>0 { residual[edge]-=pushed; residual[16*v+u]+=pushed; return pushed }
        }
        cursor[u]+=1
    }
    return 0
}

@(export)
dinic_capacity_scaling :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input==nil || length<4 || length>197 do return -1
    nv,mv,sv,tv:=input[0],input[1],input[2],input[3]
    if nv<2 || nv>16 || mv<0 || mv>64 || sv<1 || sv>nv || tv<1 || tv>nv || sv==tv do return -1
    n,m,source,sink:=int(nv),int(mv),int(sv-1),int(tv-1)
    if length!=c.size_t(4+3*m) do return -1
    residual: [256]i64 = {}
    for i:=0; i<m; i+=1 {
        u,v,capacity:=input[4+3*i],input[5+3*i],input[6+3*i]
        if u<1 || u>nv || v<1 || v>nv || u==v || capacity<0 || capacity>100 do return -1
        residual[16*int(u-1)+int(v-1)]+=capacity
    }
    greatest:=i64(0)
    for i:=0; i<256; i+=1 { if residual[i]>greatest { greatest=residual[i] } }
    threshold:=i64(1); flow:=i64(0)
    for threshold<=greatest/2 { threshold*=2 }
    if greatest==0 { threshold=0 }
    for threshold>0 {
        for {
            level: [16]int; queue: [16]int
            for i:=0; i<16; i+=1 { level[i]=-1 }
            head,tail:=0,1; level[source]=0; queue[0]=source
            for head<tail {
                u:=queue[head]; head+=1
                for v:=0; v<n; v+=1 {
                    if level[v]<0 && residual[16*u+v]>=threshold {
                        level[v]=level[u]+1; queue[tail]=v; tail+=1
                    }
                }
            }
            if level[sink]<0 do break
            cursor: [16]int = {}
            for {
                pushed:=send(source,sink,6401,&residual,&level,&cursor,n,threshold)
                if pushed==0 do break
                flow+=pushed
            }
        }
        threshold/=2
    }
    return flow
}

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn dcs_send(u: Int, sink: Int, amount: Int64, mut residual: InlineArray[Int64, 256],
            level: InlineArray[Int, 16], mut cursor: InlineArray[Int, 16], n: Int, threshold: Int64) -> Int64:
    if u == sink: return amount
    while cursor[u] < n:
        let v = cursor[u]
        let edge = 16*u+v
        if level[v] == level[u]+1 and residual[edge] >= threshold:
            let bound = amount if amount < residual[edge] else residual[edge]
            let pushed = dcs_send(v,sink,bound,residual,level,cursor,n,threshold)
            if pushed > 0:
                residual[edge] -= pushed
                residual[16*v+u] += pushed
                return pushed
        cursor[u] += 1
    return 0

@export("dinic_capacity_scaling")
fn dinic_capacity_scaling(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 197: return -1
    let nv=input[0]
    let mv=input[1]
    let sv=input[2]
    let tv=input[3]
    if nv<2 or nv>16 or mv<0 or mv>64 or sv<1 or sv>nv or tv<1 or tv>nv or sv==tv: return -1
    let n=Int(nv)
    let m=Int(mv)
    let source=Int(sv-1)
    let sink=Int(tv-1)
    if length != c_size_t(4+3*m): return -1
    var residual = InlineArray[Int64, 256](fill=0)
    for i in range(m):
        let u=input[4+3*i]
        let v=input[5+3*i]
        let capacity=input[6+3*i]
        if u<1 or u>nv or v<1 or v>nv or u==v or capacity<0 or capacity>100: return -1
        residual[16*Int(u-1)+Int(v-1)] += capacity
    var greatest: Int64 = 0
    for i in range(256):
        if residual[i]>greatest: greatest=residual[i]
    var threshold: Int64 = 1
    var flow: Int64 = 0
    while threshold<=greatest//2: threshold*=2
    if greatest==0: threshold=0
    while threshold>0:
        while True:
            var level=InlineArray[Int,16](fill=-1)
            var queue=InlineArray[Int,16](fill=0)
            var head=0
            var tail=1
            level[source]=0
            queue[0]=source
            while head<tail:
                let u=queue[head]
                head+=1
                for v in range(n):
                    if level[v]<0 and residual[16*u+v]>=threshold:
                        level[v]=level[u]+1
                        queue[tail]=v
                        tail+=1
            if level[sink]<0: break
            var cursor=InlineArray[Int,16](fill=0)
            while True:
                let pushed=dcs_send(source,sink,6401,residual,level,cursor,n,threshold)
                if pushed==0: break
                flow+=pushed
        threshold//=2
    return flow

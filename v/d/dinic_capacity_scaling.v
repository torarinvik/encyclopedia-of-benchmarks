fn dcs_send(u int, sink int, amount i64, mut residual [256]i64, level [16]int,
            mut cursor [16]int, n int, threshold i64) i64 {
    if u == sink { return amount }
    for cursor[u] < n {
        v := cursor[u]
        edge := 16*u+v
        if level[v] == level[u]+1 && residual[edge] >= threshold {
            pushed := dcs_send(v,sink,if amount < residual[edge] { amount } else { residual[edge] },
                               mut residual,level,mut cursor,n,threshold)
            if pushed > 0 { residual[edge] -= pushed; residual[16*v+u] += pushed; return pushed }
        }
        cursor[u]++
    }
    return 0
}

@[export: 'dinic_capacity_scaling']
pub fn dinic_capacity_scaling(input &i64, length usize) i64 {
    if length < 4 || length > 197 { return -1 }
    unsafe {
        if input == nil { return -1 }
        nv,mv,sv,tv := input[0],input[1],input[2],input[3]
        if nv<2 || nv>16 || mv<0 || mv>64 || sv<1 || sv>nv || tv<1 || tv>nv || sv==tv { return -1 }
        n,m,source,sink := int(nv),int(mv),int(sv-1),int(tv-1)
        if length != usize(4+3*m) { return -1 }
        mut residual := [256]i64{}
        for i in 0 .. m {
            u,v,capacity := input[4+3*i],input[5+3*i],input[6+3*i]
            if u<1 || u>nv || v<1 || v>nv || u==v || capacity<0 || capacity>100 { return -1 }
            residual[16*int(u-1)+int(v-1)] += capacity
        }
        mut greatest := i64(0)
        for value in residual { if value>greatest { greatest=value } }
        mut threshold := i64(1)
        mut flow := i64(0)
        for threshold<=greatest/2 { threshold*=2 }
        if greatest==0 { threshold=0 }
        for threshold>0 {
            for {
                mut level := [16]int{}
                mut queue := [16]int{}
                for i in 0 .. 16 { level[i]=-1 }
                mut head := 0
                mut tail := 1
                level[source]=0; queue[0]=source
                for head<tail {
                    u:=queue[head]; head++
                    for v in 0 .. n {
                        if level[v]<0 && residual[16*u+v]>=threshold {
                            level[v]=level[u]+1; queue[tail]=v; tail++
                        }
                    }
                }
                if level[sink]<0 { break }
                mut cursor := [16]int{}
                for {
                    pushed:=dcs_send(source,sink,6401,mut residual,level,mut cursor,n,threshold)
                    if pushed==0 { break }
                    flow+=pushed
                }
            }
            threshold/=2
        }
        return flow
    }
}

@[export: 'highest_label_push_relabel']
pub fn highest_label_push_relabel(input &i64, length usize) i64 {
    if length<4 || length>197 { return -1 }
    unsafe {
        if input==nil { return -1 }
        nv,mv,sv,tv:=input[0],input[1],input[2],input[3]
        if nv<2 || nv>16 || mv<0 || mv>64 || sv<1 || sv>nv || tv<1 || tv>nv || sv==tv { return -1 }
        n,m,source,sink:=int(nv),int(mv),int(sv-1),int(tv-1)
        if length!=usize(4+3*m) { return -1 }
        mut residual:=[256]i64{}
        mut excess:=[16]i64{}
        mut height:=[16]int{}
        for i in 0 .. m {
            u,v,capacity:=input[4+3*i],input[5+3*i],input[6+3*i]
            if u<1 || u>nv || v<1 || v>nv || u==v || capacity<0 || capacity>100 { return -1 }
            residual[16*int(u-1)+int(v-1)]+=capacity
        }
        height[source]=n
        for v in 0 .. n {
            amount:=residual[16*source+v]; residual[16*source+v]=0
            residual[16*v+source]+=amount; excess[v]+=amount; excess[source]-=amount
        }
        for {
            mut active:=-1
            for v in 0 .. n {
                if v!=source && v!=sink && excess[v]>0 && (active<0 || height[v]>height[active]) { active=v }
            }
            if active<0 { return excess[sink] }
            mut destination:=-1
            mut minimum:=2*n+1
            for v in 0 .. n {
                if residual[16*active+v]>0 {
                    if height[v]<minimum { minimum=height[v] }
                    if destination<0 && height[active]==height[v]+1 { destination=v }
                }
            }
            if destination<0 {
                if minimum>2*n { return -1 }
                height[active]=minimum+1
            } else {
                mut amount:=excess[active]
                if residual[16*active+destination]<amount { amount=residual[16*active+destination] }
                residual[16*active+destination]-=amount; residual[16*destination+active]+=amount
                excess[active]-=amount; excess[destination]+=amount
            }
        }
    }
}

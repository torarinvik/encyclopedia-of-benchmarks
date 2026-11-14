// Uncompiled exact-length shortest-walk draft.
@[export: 'fixed_length_walk_minplus']
pub fn fixed_length_walk_minplus(input &i64, length usize) i64 {
    if length < 4 || length > 261 { return -100000002 }
    unsafe {
        if input == nil { return -100000002 }
        nv := input[0]
        mut k := input[1]
        source, target := input[2], input[3]
        if nv<1 || nv>16 || k<0 || k>1000000 || source<0 || source>=nv || target<0 || target>=nv || length!=usize(4+nv*nv) { return -100000002 }
        n := int(nv)
        inf := i64(1000000000000000)
        mut matrix := [256]i64{}
        mut next := [256]i64{}
        mut distance := [16]i64{}
        mut temp := [16]i64{}
        for i in 0 .. n {
            distance[i] = inf
            for j in 0 .. n {
                w := input[4+i*n+j]
                if w!=1000000 && (w < -100 || w>100) { return -100000002 }
                matrix[16*i+j] = if w==1000000 { inf } else { w }
            }
        }
        distance[int(source)] = 0
        for k>0 {
            if k%2!=0 {
                for j in 0 .. n {
                    temp[j] = inf
                    for i in 0 .. n {
                        edge := matrix[16*i+j]
                        if distance[i]!=inf && edge!=inf && distance[i]+edge<temp[j] { temp[j]=distance[i]+edge }
                    }
                }
                for i in 0 .. n { distance[i]=temp[i] }
            }
            k /= 2
            if k>0 {
                for i in 0 .. n { for j in 0 .. n {
                    index := 16*i+j
                    next[index] = inf
                    for p in 0 .. n {
                        a,b := matrix[16*i+p],matrix[16*p+j]
                        if a!=inf && b!=inf && a+b<next[index] { next[index]=a+b }
                    }
                } }
                for i in 0 .. n { for j in 0 .. n { matrix[16*i+j]=next[16*i+j] } }
            }
        }
        if distance[int(target)]==inf { return -100000001 }
        return distance[int(target)]
    }
}

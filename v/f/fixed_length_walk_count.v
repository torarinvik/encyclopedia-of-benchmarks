// Uncompiled exact-length walk counting draft.
@[export: 'fixed_length_walk_count']
pub fn fixed_length_walk_count(input &i64, length usize) i64 {
    if length<4 || length>261 { return -1 }
    unsafe {
        if input==nil { return -1 }
        nv:=input[0]
        mut k:=input[1]
        source,target:=input[2],input[3]
        if nv<1 || nv>16 || k<0 || k>1000000000 || source<0 || source>=nv || target<0 || target>=nv || length!=usize(4+nv*nv) { return -1 }
        n:=int(nv)
        modulus:=i64(1000000007)
        mut matrix:=[256]i64{}
        mut next:=[256]i64{}
        mut vector:=[16]i64{}
        mut temp:=[16]i64{}
        for i in 0 .. n { for j in 0 .. n {
            value:=input[4+i*n+j]
            if value<0 || value>100 { return -1 }
            matrix[16*i+j]=value
        } }
        vector[int(source)]=1
        for k>0 {
            if k%2!=0 {
                for j in 0 .. n {
                    temp[j]=0
                    for i in 0 .. n { temp[j]=(temp[j]+vector[i]*matrix[16*i+j])%modulus }
                }
                for i in 0 .. n { vector[i]=temp[i] }
            }
            k/=2
            if k>0 {
                for i in 0 .. n { for j in 0 .. n {
                    index:=16*i+j
                    next[index]=0
                    for p in 0 .. n { next[index]=(next[index]+matrix[16*i+p]*matrix[16*p+j])%modulus }
                } }
                for i in 0 .. n { for j in 0 .. n { matrix[16*i+j]=next[16*i+j] } }
            }
        }
        return vector[int(target)]
    }
}

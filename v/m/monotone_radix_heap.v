fn mrh_bucket(key u32, last u32) int {
    mut difference:=key^last
    mut bits:=0
    for difference!=0 { bits++; difference>>=1 }
    return bits
}

@[export: 'monotone_radix_heap']
pub fn monotone_radix_heap(input &i64, length usize) i64 {
    if length<1 || length>130 { return -1 }
    unsafe {
        if input==nil || input[0]<0 || input[0]>64 { return -1 }
        q:=int(input[0])
        if length!=usize(1+2*q) { return -1 }
        mut heads:=[32]int{}
        mut next:=[64]int{}
        mut keys:=[64]u32{}
        for i in 0 .. 32 { heads[i]=-1 }
        mut used:=0
        mut removals:=i64(0)
        mut last:=u32(0)
        mut result:=i64(0)
        for i in 0 .. q {
            op,key:=input[1+2*i],input[2+2*i]
            if op==0 {
                if key<i64(last) || key>2147483647 { return -1 }
                value:=u32(key)
                bucket:=mrh_bucket(value,last)
                keys[used]=value; next[used]=heads[bucket]; heads[bucket]=used; used++
            } else if op==1 && key==0 {
                if heads[0]<0 {
                    mut bucket:=1
                    for bucket<32 && heads[bucket]<0 { bucket++ }
                    if bucket==32 { return -1 }
                    mut smallest:=u32(4294967295)
                    mut node:=heads[bucket]
                    for node>=0 {
                        if keys[node]<smallest { smallest=keys[node] }
                        node=next[node]
                    }
                    last=smallest; node=heads[bucket]; heads[bucket]=-1
                    for node>=0 {
                        following:=next[node]; destination:=mrh_bucket(keys[node],last)
                        next[node]=heads[destination]; heads[destination]=node; node=following
                    }
                }
                node:=heads[0]; heads[0]=next[node]; removals++
                result+=removals*i64(keys[node])
            } else { return -1 }
        }
        return result
    }
}

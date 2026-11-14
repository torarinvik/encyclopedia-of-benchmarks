package monotone_radix_heap
import "core:c"

bucket_of :: proc(key,last: u32) -> int {
    difference:=key~last
    bits:=0
    for difference!=0 { bits+=1; difference>>=1 }
    return bits
}

@(export)
monotone_radix_heap :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input==nil || length<1 || length>130 do return -1
    if input[0]<0 || input[0]>64 do return -1
    q:=int(input[0])
    if length!=c.size_t(1+2*q) do return -1
    heads: [32]int; next: [64]int; keys: [64]u32
    for i:=0; i<32; i+=1 { heads[i]=-1 }
    used:=0; removals:=i64(0); last:=u32(0); result:=i64(0)
    for i:=0; i<q; i+=1 {
        op,key:=input[1+2*i],input[2+2*i]
        if op==0 {
            if key<i64(last) || key>2147483647 do return -1
            value:=u32(key); bucket:=bucket_of(value,last)
            keys[used]=value; next[used]=heads[bucket]; heads[bucket]=used; used+=1
        } else if op==1 && key==0 {
            if heads[0]<0 {
                bucket:=1
                for bucket<32 && heads[bucket]<0 { bucket+=1 }
                if bucket==32 do return -1
                smallest:=u32(4294967295); node:=heads[bucket]
                for node>=0 { smallest=min(smallest,keys[node]); node=next[node] }
                last=smallest; node=heads[bucket]; heads[bucket]=-1
                for node>=0 {
                    following:=next[node]; destination:=bucket_of(keys[node],last)
                    next[node]=heads[destination]; heads[destination]=node; node=following
                }
            }
            node:=heads[0]; heads[0]=next[node]; removals+=1
            result+=removals*i64(keys[node])
        } else { return -1 }
    }
    return result
}

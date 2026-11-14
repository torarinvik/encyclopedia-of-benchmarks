from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn mrh_bucket(key: UInt32, last: UInt32) -> Int:
    var difference=key ^ last
    var bits=0
    while difference!=0:
        bits+=1
        difference>>=1
    return bits

@export("monotone_radix_heap")
fn monotone_radix_heap(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64, ImmutAnyOrigin]() or length<1 or length>130: return -1
    if input[0]<0 or input[0]>64: return -1
    let q=Int(input[0])
    if length!=c_size_t(1+2*q): return -1
    var heads=InlineArray[Int,32](fill=-1)
    var next=InlineArray[Int,64](fill=-1)
    var keys=InlineArray[UInt32,64](fill=0)
    var used=0
    var removals: Int64=0
    var last: UInt32=0
    var result: Int64=0
    for i in range(q):
        let op=input[1+2*i]
        let key=input[2+2*i]
        if op==0:
            if key<Int64(last) or key>2147483647: return -1
            let value=UInt32(key)
            let bucket=mrh_bucket(value,last)
            keys[used]=value
            next[used]=heads[bucket]
            heads[bucket]=used
            used+=1
        elif op==1 and key==0:
            if heads[0]<0:
                var bucket=1
                while bucket<32 and heads[bucket]<0: bucket+=1
                if bucket==32: return -1
                var smallest=UInt32(4294967295)
                var node=heads[bucket]
                while node>=0:
                    if keys[node]<smallest: smallest=keys[node]
                    node=next[node]
                last=smallest
                node=heads[bucket]
                heads[bucket] = -1
                while node>=0:
                    let following=next[node]
                    let destination=mrh_bucket(keys[node],last)
                    next[node]=heads[destination]
                    heads[destination]=node
                    node=following
            let node=heads[0]
            heads[0]=next[node]
            removals+=1
            result+=removals*Int64(keys[node])
        else: return -1
    return result

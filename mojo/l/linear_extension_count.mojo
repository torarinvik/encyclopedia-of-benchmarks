from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 12
const MAX_LENGTH = 14
const MAX_STATES = 4096

@export("linear_extension_count")
fn linear_extension_count(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>MAX_LENGTH: return -1
    if input[0]<0 or input[0]>MAX_N: return -1
    let n=Int(input[0])
    if length!=c_size_t(n+1): return -1
    let full=(1<<n)-1
    var predecessor=InlineArray[Int,MAX_N](fill=0)
    for vertex in range(n):
        if input[1+vertex]<0 or input[1+vertex]>full: return -1
        predecessor[vertex]=Int(input[1+vertex])

    var ways=InlineArray[Int64,MAX_STATES](fill=0)
    ways[0]=1
    for prefix in range(full+1):
        let count=ways[prefix]
        if count==0: continue
        for vertex in range(n):
            let bit=1<<vertex
            if (prefix&bit)==0 and (predecessor[vertex]&prefix)==predecessor[vertex]:
                ways[prefix|bit]=ways[prefix|bit]+count
    return ways[full]

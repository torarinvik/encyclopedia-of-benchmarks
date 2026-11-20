from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 8
const MAX_M = 28
const MAX_LENGTH = 58

@export("dag_transitive_reduction")
fn dag_transitive_reduction(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>MAX_LENGTH+1: return -1
    if input[0]<1 or input[0]>MAX_N or input[1]<0 or input[1]>MAX_M: return -1
    let n=Int(input[0])
    let m=Int(input[1])
    if length!=c_size_t(2+2*m): return -1

    var outgoing=InlineArray[Int,MAX_N](fill=0)
    for edge in range(m):
        let tail_value=input[2+2*edge]
        let head_value=input[3+2*edge]
        if tail_value<0 or head_value<0 or tail_value>=n or head_value>=n or tail_value==head_value: return -1
        let tail=Int(tail_value)
        let head=Int(head_value)
        let bit=1<<head
        if (outgoing[tail]&bit)!=0: return -1
        outgoing[tail]=outgoing[tail]|bit

    var reach=InlineArray[Int,MAX_N](fill=0)
    for vertex in range(n): reach[vertex]=outgoing[vertex]
    for middle in range(n):
        for source in range(n):
            if (reach[source]&(1<<middle))!=0:
                reach[source]=reach[source]|reach[middle]
    for vertex in range(n):
        if (reach[vertex]&(1<<vertex))!=0: return -1

    var retained:Int64=0
    for edge in range(m):
        let tail=Int(input[2+2*edge])
        let head=Int(input[3+2*edge])
        var redundant=false
        for middle in range(n):
            if middle!=tail and middle!=head and (outgoing[tail]&(1<<middle))!=0 and (reach[middle]&(1<<head))!=0:
                redundant=true
        if not redundant: retained=retained+1
    return retained

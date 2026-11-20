from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 8
const MAX_M = 56
const MAX_LENGTH = 114
const MAX_STATES = 256
const INF = 2305843009213693951

@export("minimum_directed_feedback_arc_set")
fn minimum_directed_feedback_arc_set(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
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

    let full=(1<<n)-1
    var dp=InlineArray[Int64,MAX_STATES](fill=INF)
    dp[0]=0
    for prefix in range(full+1):
        if dp[prefix]==INF: continue
        for vertex in range(n):
            let bit=1<<vertex
            if (prefix&bit)!=0: continue
            var backward:Int64=0
            for prior in range(n):
                if (prefix&(1<<prior))!=0 and (outgoing[vertex]&(1<<prior))!=0:
                    backward=backward+1
            let target=prefix|bit
            let candidate=dp[prefix]+backward
            if candidate<dp[target]: dp[target]=candidate
    return dp[full]

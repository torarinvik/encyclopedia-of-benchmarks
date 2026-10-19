from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("hamiltonian_path_exists")
fn hamiltonian_path_exists(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>65 or input[0]<0 or input[0]>8:return -1
    let n=Int(input[0]);if length!=c_size_t(1+n*n):return -1
    var graph=InlineArray[Int64,64](fill=0)
    for row in range(n):
        for col in range(n):
            let cell=input[1+row*n+col]
            if cell!=0 and cell!=1:return -1
            graph[row*8+col]=cell
    var dp=InlineArray[Int64,2048](fill=0)
    for start in range(n):dp[(1<<start)*8+start]=1
    let full=(1<<n)-1
    for mask in range(1,full+1):
        for last in range(n):
            if dp[mask*8+last]==0:continue
            for next in range(n):
                if (mask&(1<<next))==0 and graph[last*8+next]!=0:dp[(mask|(1<<next))*8+next]=1
    for last in range(n):if dp[full*8+last]!=0:return 1
    return 0

# Bounded Thorup-Zwick k=2 oracle; see the package README and RIGHTS.md.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("thorup_zwick_distance_oracle")
fn thorup_zwick_distance_oracle(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>266: return -1
    let n64=input[0]; let m64=input[1]; let mask=input[2]
    if n64<1 or n64>12 or m64<0 or m64>66: return -1
    let n=Int(n64); let m=Int(m64)
    if mask<=0 or (mask >> n)!=0: return -1
    let query_at=3+3*m
    if query_at>=Int(length): return -1
    let q64=input[query_at]
    if q64<0 or q64>32 or length!=c_size_t(query_at+1+2*Int(q64)): return -1
    let q=Int(q64)
    let inf=Int64(0x3fffffffffffffff)
    var distance=InlineArray[Int64,144](fill=0)
    for u in range(n):
        for v in range(n): distance[12*u+v]=0 if u==v else inf
    for e in range(m):
        let u64=input[3+3*e]; let v64=input[4+3*e]; let weight=input[5+3*e]
        if u64<0 or v64<=u64 or v64>=n64 or weight<1 or weight>1000: return -1
        let u=Int(u64); let v=Int(v64)
        if distance[12*u+v]!=inf: return -1
        distance[12*u+v]=weight; distance[12*v+u]=weight
    for k in range(n):
        for i in range(n):
            for j in range(n):
                let a=distance[12*i+k]; let b=distance[12*k+j]
                if a!=inf and b!=inf and a+b<distance[12*i+j]: distance[12*i+j]=a+b
    for i in range(n):
        for j in range(n):
            if distance[12*i+j]==inf: return -1
    var nearest=InlineArray[Int,12](fill=0)
    var nearest_distance=InlineArray[Int64,12](fill=0)
    for v in range(n):
        var best=inf; var pivot = -1
        for a in range(n):
            if ((mask >> a) & 1)!=0:
                let value=distance[12*v+a]
                if value<best or (value==best and a<pivot): best=value; pivot=a
        nearest[v]=pivot; nearest_distance[v]=best
    var bunch=InlineArray[Bool,144](fill=False)
    for u in range(n):
        for v in range(n):
            bunch[12*u+v]=((mask >> v) & 1)!=0 or distance[12*u+v]<nearest_distance[u]
    var words=InlineArray[Int64,33](fill=0)
    words[0]=q64
    for i in range(q):
        let u64=input[query_at+1+2*i]; let v64=input[query_at+2+2*i]
        if u64<0 or u64>=n64 or v64<0 or v64>=n64: return -1
        var u=Int(u64); var v=Int(v64); var found=False
        for level in range(2):
            let pivot=v if level==0 else nearest[v]
            if bunch[12*u+pivot]:
                words[1+i]=distance[12*u+pivot]+distance[12*v+pivot]
                found=True
                break
            let temp=u; u=v; v=temp
        if not found: return -1
    let bytes=8*(q+1)
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes): return -2
    for i in range(q+1):
        let bits=bitcast[UInt64](words[i])
        for byte in range(8): output[8*i+byte]=UInt8((bits >> UInt(8*byte)) & 255)
    return Int64(bytes)

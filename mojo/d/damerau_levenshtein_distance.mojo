from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List

@export("damerau_levenshtein_distance")
fn damerau_levenshtein_distance(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>66:return -1
    let m=input[0];let n=input[1]
    if m<0 or m>32 or n<0 or n>32 or length!=c_size_t(2+m+n):return -1
    for i in range(Int(m+n)):
        if input[i+2]<0 or input[i+2]>127:return -1
    let inf=Int(m+n)
    var d=List[Int](length=34*34,fill=0)
    d[0]=inf
    for i in range(1,Int(m)+2):d[i*34]=inf
    for j in range(1,Int(n)+2):d[j]=inf
    for i in range(Int(m)+1):d[(i+1)*34+1]=i
    for j in range(Int(n)+1):d[34+j+1]=j
    var last=List[Int](length=128,fill=0)
    for i in range(1,Int(m)+1):
        var db=0
        for j in range(1,Int(n)+1):
            let symbol=input[Int(m)+1+j]
            let i1=last[Int(symbol)]
            let j1=db
            var cost=1
            if input[i+1]==symbol:cost=0;db=j
            let substitute=d[(i)*34+j]+cost
            let insert=d[(i+1)*34+j]+1
            let delete=d[i*34+(j+1)]+1
            var best=min(substitute,min(insert,delete))
            if i1>0 and j1>0:
                let transposition=d[i1*34+j1]+(i-i1-1)+1+(j-j1-1)
                best=min(best,transposition)
            d[(i+1)*34+j+1]=best
        last[Int(input[i+1])]=i
    return Int64(d[(Int(m)+1)*34+Int(n)+1])

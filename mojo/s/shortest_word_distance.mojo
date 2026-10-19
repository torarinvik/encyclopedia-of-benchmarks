from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn swd_eq(a:UnsafePointer[Int64,ImmutAnyOrigin],s:Int,n:Int,t:Int,m:Int)->Bool:
    if n!=m:return False
    for i in range(n):if a[s+i]!=a[t+i]:return False
    return True
@export("shortest_word_distance")
fn shortest_word_distance(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>308:return -1
    let wc=a[0];if wc<2 or wc>32:return -1
    var starts=InlineArray[Int32,32]();var lens=InlineArray[Int32,32]();var p=1
    for i in range(Int(wc)):
        if p>=Int(n):return -1
        let l=a[p];p+=1;if l<1 or l>8 or p+Int(l)>Int(n):return -1
        starts[i]=Int32(p);lens[i]=Int32(l)
        for j in range(Int(l)):let c=a[p+j];if not ((c>=65 and c<=90) or (c>=97 and c<=122)):return -1
        p+=Int(l)
    var targetstart=InlineArray[Int32,2]();var targetlen=InlineArray[Int32,2]()
    for t in range(2):
        if p>=Int(n):return -1
        let l=a[p];p+=1;if l<1 or l>8 or p+Int(l)>Int(n):return -1
        targetstart[t]=Int32(p);targetlen[t]=Int32(l)
        for j in range(Int(l)):let c=a[p+j];if not ((c>=65 and c<=90) or (c>=97 and c<=122)):return -1
        p+=Int(l)
    if p!=Int(n) or swd_eq(a,Int(targetstart[0]),Int(targetlen[0]),Int(targetstart[1]),Int(targetlen[1])):return -1
    var have0=False;var have1=False;var best=Int(wc)
    for i in range(Int(wc)):
        let x=swd_eq(a,Int(starts[i]),Int(lens[i]),Int(targetstart[0]),Int(targetlen[0]));let y=swd_eq(a,Int(starts[i]),Int(lens[i]),Int(targetstart[1]),Int(targetlen[1]));have0=have0 or x;have1=have1 or y
        for j in range(Int(wc)):
            let c=swd_eq(a,Int(starts[j]),Int(lens[j]),Int(targetstart[0]),Int(targetlen[0]));let d=swd_eq(a,Int(starts[j]),Int(lens[j]),Int(targetstart[1]),Int(targetlen[1]))
            if (x and d) or (y and c):best=min(best,abs(i-j))
    return Int64(best) if have0 and have1 else -1

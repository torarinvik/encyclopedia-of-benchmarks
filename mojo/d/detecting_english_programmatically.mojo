from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
@export("detecting_english_programmatically")
fn detecting_english_programmatically(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>170:return -1
    let size=Int(n);var p=0;let wc=a[p];p+=1
    if wc<0 or wc>8:return -1
    var starts=List[Int](capacity=8);var lengths=List[Int](capacity=8)
    for w in range(Int(wc)):
        if p>=size:return -1
        let l=a[p];p+=1
        if l<1 or l>12 or p+Int(l)>size:return -1
        let start=p
        for j in range(Int(l)):
            if a[p+j]<65 or a[p+j]>90:return -1
        if w>0:
            var cmp=0;var k=0;let prevlen=lengths[w-1];let prevstart=starts[w-1]
            while k<prevlen and k<Int(l) and a[prevstart+k]==a[p+k]:k+=1
            if k<prevlen and k<Int(l):cmp= -1 if a[prevstart+k]<a[p+k] else 1
            elif prevlen!=Int(l):cmp= -1 if prevlen<Int(l) else 1
            if cmp>=0:return -1
        starts.append(start);lengths.append(Int(l));p+=Int(l)
    if p>=size:return -1
    let ml=a[p];p+=1
    if ml<1 or ml>64 or p+Int(ml)+2!=size:return -1
    let ms=p
    for i in range(Int(ml)):if a[ms+i]<0 or a[ms+i]>127:return -1
    p+=Int(ml);let wp=a[p];let lp=a[p+1]
    if wp<0 or wp>100 or lp<0 or lp>100:return -1
    var retained=0;var tokens=0;var hits=0;var i=0;var token=List[Int](capacity=64)
    while i<=Int(ml):
        var c:Int64=32
        if i<Int(ml):c=a[ms+i]
        let letter=(c>=65 and c<=90) or (c>=97 and c<=122);let ws=c==9 or c==10 or c==32
        if i<Int(ml) and (letter or ws):retained+=1
        if letter:
            token.append(Int(c-32 if c>=97 else c));i+=1;continue
        if not ws:i+=1;continue
        if len(token)==0:i+=1;continue
        tokens+=1
        for w in range(Int(wc)):
            if lengths[w]!=len(token):continue
            var k=0
            while k<len(token) and a[starts[w]+k]==Int64(token[k]):k+=1
            if k==len(token):hits+=1;break
        token=List[Int](capacity=64);i+=1
    if tokens==0:return -1
    return 1 if hits*100>=Int(wp)*tokens and retained*100>=Int(lp)*Int(ml) else 0

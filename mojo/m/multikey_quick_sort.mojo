from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mk_char(d:InlineArray[Int32,512],lens:InlineArray[Int32,32],i:Int,depth:Int)->Int:
    if depth>=lens[i]:return 0
    return Int(d[i*16+depth])
fn mk_cmp(d:InlineArray[Int32,512],lens:InlineArray[Int32,32],a:Int,b:Int,depth:Int)->Int:
    var k=depth
    while k<lens[a] and k<lens[b] and d[a*16+k]==d[b*16+k]:k+=1
    let x=mk_char(d,lens,a,k);let y=mk_char(d,lens,b,k)
    return (x>y)-(x<y)
fn mk_median(a:Int,b:Int,c:Int)->Int:
    if a<b:return b if b<c else (c if a<c else a)
    return b if b>c else (a if a<c else c)
fn mk_swap(mut d:InlineArray[Int32,512],mut lens:InlineArray[Int32,32],a:Int,b:Int):
    if a==b:return
    let len=lens[a];lens[a]=lens[b];lens[b]=len
    for j in range(16):let x=d[a*16+j];d[a*16+j]=d[b*16+j];d[b*16+j]=x
fn mk_sort(mut d:InlineArray[Int32,512],mut lens:InlineArray[Int32,32],lo:Int,hi:Int,depth:Int):
    let n=hi-lo
    if n<10:
        for i in range(lo+1,hi):
            var j=i
            while j>lo and mk_cmp(d,lens,j-1,j,depth)>0:mk_swap(d,lens,j-1,j);j-=1
        return
    let mid=lo+n/2;let pivot=mk_median(mk_char(d,lens,lo,depth),mk_char(d,lens,mid,depth),mk_char(d,lens,hi-1,depth))
    var less=lo;var scan=lo;var greater=hi
    while scan<greater:
        let key=mk_char(d,lens,scan,depth)
        if key<pivot:mk_swap(d,lens,less,scan);less+=1;scan+=1
        elif key>pivot:greater-=1;mk_swap(d,lens,greater,scan)
        else:scan+=1
    mk_sort(d,lens,lo,less,depth)
    if pivot!=0:mk_sort(d,lens,less,greater,depth+1)
    mk_sort(d,lens,greater,hi,depth)
fn mk_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int32):
    let u=UInt32(x)
    for b in range(4):o[p+4*b]=UInt8((u>>(8*b))&255)
@export("multikey_quick_sort")
fn multikey_quick_sort(v:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int32,ImmutAnyOrigin]() or n<1 or n>546:return -1
    let count=Int(v[0]);if count<0 or count>32:return -1
    var data=InlineArray[Int32,512](fill=0);var lens=InlineArray[Int32,32](fill=0);var p=1
    for i in range(count):
        if p>=Int(n) or v[p]<0 or v[p]>16:return -1
        let size=Int(v[p]);p+=1;if size>0 and p+size>Int(n):return -1;lens[i]=Int32(size)
        for j in range(size):if v[p]<1 or v[p]>127:return -1;data[i*16+j]=v[p];p+=1
    if p!=Int(n):return -1
    let bytes=4*Int(n);if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    mk_sort(data,lens,0,count,0);var w=0;mk_put(o,w,Int32(count));w+=4
    for i in range(count):mk_put(o,w,lens[i]);w+=4;for j in range(Int(lens[i])):mk_put(o,w,data[i*16+j]);w+=4
    return Int64(bytes)

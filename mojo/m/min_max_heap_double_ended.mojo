from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mmd_minlevel(i:Int)->Bool:
    var x=i+1;var depth=0
    while x>1:x>>=1;depth+=1
    return depth%2==0
fn mmd_better(a:Int32,b:Int32,findmin:Bool)->Bool:
    return a<b if findmin else a>b
fn mmd_swap(mut h:InlineArray[Int32,192],a:Int,b:Int):
    let t=h[a];h[a]=h[b];h[b]=t
fn mmd_best(h:InlineArray[Int32,192],size:Int,i:Int,findmin:Bool)->Int:
    var best=i
    for q in range(6):
        let c=if q<2:2*i+1+q else:4*i+1+q
        if c<size and (best==i or mmd_better(h[c],h[best],findmin)):best=c
    return best
fn mmd_down(mut h:InlineArray[Int32,192],size:Int,start:Int,findmin:Bool):
    var i=start
    while i<size:
        let b=mmd_best(h,size,i,findmin)
        if b==i:return
        let grand=b>2 and (b-3)//4==i
        if grand:
            if not mmd_better(h[b],h[i],findmin):return
            mmd_swap(mut h,b,i);let parent=(b-1)//2
            if mmd_better(h[parent],h[b],findmin):mmd_swap(mut h,b,parent)
            i=b
        else:
            if mmd_better(h[b],h[i],findmin):mmd_swap(mut h,b,i)
            return
fn mmd_up(mut h:InlineArray[Int32,192],i0:Int,findmin:Bool):
    var i=i0
    while i>2:
        let gp=(i-3)//4
        if not mmd_better(h[i],h[gp],findmin):return
        mmd_swap(mut h,i,gp);i=gp
fn mmd_add(mut h:InlineArray[Int32,192],mut size:Int,x:Int32):
    let i=size;h[i]=x;size+=1
    if i==0:return
    let p=(i-1)//2
    if mmd_minlevel(i):
        if h[i]>h[p]:mmd_swap(mut h,i,p);mmd_up(mut h,p,False)
        else:mmd_up(mut h,i,True)
    else:
        if h[i]<h[p]:mmd_swap(mut h,i,p);mmd_up(mut h,p,True)
        else:mmd_up(mut h,i,False)
fn mmd_maxindex(h:InlineArray[Int32,192],size:Int)->Int:
    if size<2:return 0
    if size==2:return 1
    return 1 if h[1]>h[2] else 2
fn mmd_extract(mut h:InlineArray[Int32,192],mut size:Int,index:Int)->Int32:
    let result=h[index];size-=1
    if index<size:h[index]=h[size]
    if size>0 and index<size:mmd_down(mut h,size,index,mmd_minlevel(index))
    return result
fn mmd_put(out:UnsafePointer[UInt8,MutAnyOrigin],mut p:Int,x:Int64):
    let u=UInt64(x)
    for b in range(8):out[p]=UInt8((u>>(8*b))&255);p+=1
@export("min_max_heap_double_ended")
fn min_max_heap_double_ended(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>322 or v[0]<0 or v[0]>64:return -1
    let init=Int(v[0]);let op_pos=init+1
    if op_pos>=Int(n) or v[op_pos]<0 or v[op_pos]>128:return -1
    let ops=Int(v[op_pos]);if Int(n)!=init+2+2*ops:return -1
    for i in range(init):if v[i+1] < -2147483648 or v[i+1]>2147483647:return -1
    for i in range(ops):
        let op=v[init+2+2*i];let arg=v[init+3+2*i]
        if op<0 or op>5 or (op==0 and (arg < -2147483648 or arg>2147483647)) or (op!=0 and arg!=0):return -1
    var h=InlineArray[Int32,192](fill=0);var size=init
    for i in range(init):h[i]=Int32(v[i+1])
    for i in range(init//2):mmd_down(mut h,size,init//2-1-i,mmd_minlevel(init//2-1-i))
    var events=InlineArray[Int64,128](fill=0);var ec=0
    for i in range(ops):
        let op=v[init+2+2*i];let arg=v[init+3+2*i]
        if op==0:mmd_add(mut h,mut size,Int32(arg))
        elif op==1 or op==2 or op==3 or op==4:
            if size==0:return -1
            let idx=if op==1 or op==3:0 else:mmd_maxindex(h,size);let val=Int64(h[idx])
            events[ec]=val;ec+=1
            if op==3 or op==4:let removed=mmd_extract(mut h,mut size,idx)
        else:events[ec]=Int64(size);ec+=1
    for i in range(1,size):
        let x=h[i];var j=i
        while j>0 and h[j-1]>x:h[j]=h[j-1];j-=1
        h[j]=x
    let words=2+ec+size;let bytes=words*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var p=0;mmd_put(out,mut p,Int64(ec))
    for i in range(ec):mmd_put(out,mut p,events[i])
    mmd_put(out,mut p,Int64(size))
    for i in range(size):mmd_put(out,mut p,Int64(h[i]))
    return Int64(bytes)

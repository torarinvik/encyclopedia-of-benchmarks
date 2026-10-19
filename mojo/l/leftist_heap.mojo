from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

fn merge_heap(mut key:InlineArray[Int64,14],mut left:InlineArray[Int64,14],mut right:InlineArray[Int64,14],mut npl:InlineArray[Int64,14],x0:Int,y0:Int)->Int:
    if x0<0:return y0
    if y0<0:return x0
    var x=x0;var y=y0
    if key[x]>key[y]:let t=x;x=y;y=t
    right[x]=Int64(merge_heap(key,left,right,npl,Int(right[x]),y))
    if left[x]<0:left[x]=right[x];right[x]=-1
    else:
        if npl[left[x]]<npl[right[x]]:let t=left[x];left[x]=right[x];right[x]=t
        npl[x]=npl[right[x]]+1
    return x

@export("leftist_heap")
fn leftist_heap(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>43:return -1.0e300
    let m=v[0]
    if m<0 or m>14 or n!=c_size_t(1+3*m):return -1.0e300
    var key=InlineArray[Int64,14](fill=0);var left=InlineArray[Int64,14](fill=-1);var right=InlineArray[Int64,14](fill=-1);var npl=InlineArray[Int64,14](fill=0)
    var roots=InlineArray[Int64,2](fill=-1);var used=0;var extracts=0;var result:Int64=0
    for i in range(Int(m)):
        let p=1+3*i;let op=v[p];let h=v[p+1];let z=v[p+2]
        if op<0 or op>3:return -1.0e300
        if op==0:
            if h<0 or h>1 or z<0 or z>9:return -1.0e300
            key[used]=z;roots[h]=Int64(merge_heap(key,left,right,npl,used,Int(roots[h])));used+=1
        elif op==1:
            if h<0 or h>1 or z!=0:return -1.0e300
            extracts+=1
            if extracts>10:return -1.0e300
            let r=Int(roots[h]);var got:Int64=-1
            if r>=0:got=key[r];roots[h]=Int64(merge_heap(key,left,right,npl,Int(left[r]),Int(right[r])))
            result=result*13+got+2
        elif op==2:
            if h!=0 or z!=0:return -1.0e300
            roots[0]=Int64(merge_heap(key,left,right,npl,Int(roots[0]),Int(roots[1])));roots[1]=-1
        else:
            if h<0 or h>1 or z!=0:return -1.0e300
            roots[h]=-1
    return Float64(result)

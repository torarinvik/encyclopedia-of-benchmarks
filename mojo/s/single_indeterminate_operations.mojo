from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from math import pow
@export("single_indeterminate_operations")
fn single_indeterminate_operations(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<3 or n>22:return -1
    let opv=a[0];if not (opv>=0.0 and opv<=5.0 and opv==Float64(Int(opv))):return -1
    let op=Int(opv);var cur=1
    let daV=a[cur];if not (daV>=0.0 and daV<=8.0 and daV==Float64(Int(daV))):return -1
    let da=Int(daV);cur+=1;var av=InlineArray[Float64,9]()
    if n<c_size_t(cur+da+1):return -1
    for i in range(da+1):av[i]=a[cur+i];if not (av[i]>=-10.0 and av[i]<=10.0):return -1
    cur+=da+1;var db=0;var bv=InlineArray[Float64,9]();var x=0.0
    if op<=2:
        if n<c_size_t(cur+1):return -1
        let dbv=a[cur];if not (dbv>=0.0 and dbv<=8.0 and dbv==Float64(Int(dbv))):return -1
        db=Int(dbv);cur+=1;if n<c_size_t(cur+db+1):return -1
        for i in range(db+1):bv[i]=a[cur+i];if not (bv[i]>=-10.0 and bv[i]<=10.0):return -1
        cur+=db+1
    elif op==3 or op==5:
        if cur>=Int(n):return -1
        x=a[cur];if op==3 and not (x>=-2.0 and x<=2.0):return -1
        if op==5 and not (x>=-10.0 and x<=10.0):return -1
        cur+=1
    if cur!=Int(n):return -1
    var out=InlineArray[Float64,17]();var count=0
    if op==0:
        count=max(da,db)+1
        for i in range(count):out[i]=bv[i] if db>=da else av[i]
        for i in range(min(da,db)+1):out[i]+=av[i] if db>=da else bv[i]
    elif op==1:
        count=max(da,db)+1
        for i in range(db+1):bv[i] = -bv[i]
        for i in range(count):out[i]=bv[i] if db>=da else av[i]
        for i in range(min(da,db)+1):out[i]+=av[i] if db>=da else bv[i]
    elif op==2:
        count=da+db+1
        for i in range(da+1):
            for j in range(db+1):out[i+j]+=av[i]*bv[j]
    elif op==3:
        count=1
        for i in range(da+1):out[0]+=av[i]*pow(x,Float64(i))
    elif op==4:
        count=da
        for i in range(da):out[i]=av[i+1]*Float64(i+1)
    else:
        count=da+2;out[0]=x
        for i in range(da+1):out[i+1]=av[i]/Float64(i+1)
    for i in range(count):if not out[i].is_finite():return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(count):return -2
    for i in range(count):o[i]=out[i]
    return count

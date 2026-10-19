from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn liarr_put(out:UnsafePointer[UInt8,MutAnyOrigin],idx:Int,x:Int32):
    let bits=bitcast[UInt32](x)
    for j in range(4):out[idx*4+j]=UInt8((bits>>(8*j))&255)
@export("linkedlist_implentation_usingarray")
fn linkedlist_implentation_usingarray(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>202 or v[0]<0 or v[0]>100 or n!=c_size_t(1+2*v[0]):return -1
    var items=InlineArray[Int32,100](fill=0);var count=0
    for i in range(Int(v[0])):
        let op=v[1+2*i];let val=v[2+2*i]
        if val < -2147483648 or val>2147483647 or count>=100:return -1
        if op==0:
            var j=count
            while j>0:items[j]=items[j-1];j-=1
            items[0]=Int32(val);count+=1
        elif op==1:
            if count==0:return -1
            items[count]=Int32(val);count+=1
        else:return -1
    let bytes=(count+1)*4
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    liarr_put(out,0,Int32(count))
    for i in range(count):liarr_put(out,i+1,items[i])
    return Int64(bytes)

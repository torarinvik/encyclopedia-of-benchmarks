from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sol_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,v:Int64):
    let z=bitcast[UInt64](v);for b in range(8):o[p+b]=UInt8((z>>UInt(8*b))&255)
@export("self_organizing_linked_list")
fn self_organizing_linked_list(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>130:return -1
    let count=a[0];if count<0 or count>64 or n!=c_size_t(1+2*count):return -1
    var items=InlineArray[Int64,64]();var size=0;var rec=InlineArray[Int64,194]();var rp=0
    for i in range(Int(count)):
        let op=a[1+2*i];let v=a[2+2*i];if v< -2147483648 or v>2147483647:return -1
        if op==0:
            if size>=64:return -1
            items[size]=v;size+=1;rec[rp]=0;rec[rp+1]=0;rp+=2
        elif op==1:
            var pos= -1;for j in range(size):if items[j]==v:pos=j;break
            rec[rp]=1;rec[rp+1]=1;rec[rp+2]=1 if pos>=0 else 0;rp+=3
            if pos>0:for j in range(pos,0,-1):items[j]=items[j-1];items[0]=v
        else:return -1
    rec[rp]=2;rec[rp+1]=size;rp+=2
    for i in range(size):rec[rp]=items[i];rp+=1
    let bytes=rp*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(rp):sol_put(o,i*8,rec[i])
    return Int64(bytes)

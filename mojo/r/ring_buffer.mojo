from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("ring_buffer")
fn ring_buffer(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>513 or v[0]<0 or v[0]>256 or Int(n)!=1+2*Int(v[0]):return -1
    let q=Int(v[0])
    for i in range(q):
        let op=v[1+2*i];let x=v[2+2*i]
        if op==0:if x< -1000000 or x>1000000:return -1
        elif op==4:if x<0 or x>1000000:return -1
        elif (op>=1 and op<=3) or (op>=5 and op<=9):if x!=0:return -1
        else:return -1
    var values=InlineArray[Int64,8](fill=0);var head=0;var tail=0;var count=0;var hash:Int64=0
    for i in range(q):
        let op=v[1+2*i];let x=v[2+2*i];var status:Int64=0;var result:Int64=0
        if op==0:if count==8:status=1 else:values[tail]=x;tail=(tail+1)%8;count+=1
        elif op==1:if count==0:status=2 else:result=values[head];head=(head+1)%8;count-=1
        elif op==2:if count==0:status=2 else:result=values[head]
        elif op==3:if count==0:status=2 else:result=values[(tail+7)%8]
        elif op==4:if x>=count:status=3 else:result=values[(head+Int(x))%8]
        elif op==5:head=0;tail=0;count=0
        elif op==6:result=Int64(count)
        elif op==7:result=Int64(8-count)
        elif op==8:if count==0:result=1
        else:if count==8:result=1
        hash=(hash*1000003+op)%1000000007;hash=(hash*1000003+status)%1000000007;hash=(hash*1000003+result+1000001)%1000000007;hash=(hash*1000003+Int64(count))%1000000007
        for j in range(count):let idx=(head+j)%8;hash=(hash*1000003+values[idx]+1000001)%1000000007
    return hash

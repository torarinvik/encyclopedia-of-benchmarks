from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn ojs_digit(mut b:InlineArray[UInt8,2048],mut pos:Int,x:UInt32):
    var tmp=InlineArray[UInt8,10](fill=UInt8(0));var k=0;var v=x
    while True:tmp[k]=UInt8(48+v%10);k+=1;v/=10;if v==0:break
    while k>0:k-=1;b[pos]=tmp[k];pos+=1
@export("optimal_job_scheduling")
fn optimal_job_scheduling(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>194 or v[0]<1 or v[0]>16 or v[1]<1 or v[1]>8:return -1
    let p=Int(v[0]);let m=Int(v[1])
    if n!=c_size_t(2+p*m+m*m):return -1
    var run=InlineArray[Int64,128](fill=0);var transfer=InlineArray[Int64,64](fill=0);var at=2
    for i in range(p*m):let x=v[at];at+=1;if x<0 or x>1000:return -1;run[i]=x
    for i in range(m*m):let x=v[at];at+=1;if x<0 or x>1000:return -1;transfer[i]=x
    var cost=InlineArray[UInt32,128](fill=0)
    for j in range(m):cost[j]=UInt32(run[j])
    for i in range(1,p):
        for j in range(m):
            var best:UInt32=4294967295
            for k in range(m):
                let x=cost[(i-1)*m+k]+UInt32(transfer[k*m+j])+UInt32(run[i*m+j])
                if x<best:best=x
            cost[i*m+j]=best
    var buf=InlineArray[UInt8,2048](fill=UInt8(0));var used=0
    for i in range(p):
        for j in range(m):
            if j>0:buf[used]=44;used+=1
            ojs_digit(buf,used,cost[i*m+j])
        if i+1<p:buf[used]=10;used+=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(used):return -2
    for i in range(used):o[i]=buf[i]
    return Int64(used)

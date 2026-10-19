from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import signbit
@export("polynom_for_points")
fn polynom_for_points(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>17 or v[0]<2 or v[0]>8 or n!=c_size_t(1+2*v[0]):return -1
    let k=Int(v[0]);var a=InlineArray[Float64,64](fill=0.0);var b=InlineArray[Float64,8](fill=0.0)
    for r in range(k):
        let x=v[1+2*r];let y=v[2+2*r]
        if x< -4 or x>4 or y< -25000 or y>25000:return -1
        for q in range(r):if v[1+2*q]==x:return -1
        for c in range(k):
            var p=Int64(1)
            for _ in range(k-c-1):p*=x
            a[r*8+c]=Float64(p)
        b[r]=Float64(y)
    for c in range(k):
        if a[c*8+c]==0.0:
            var pr=c+1
            for r in range(c+2,k):
                let x=a[r*8+c] if a[r*8+c]>=0 else -a[r*8+c]
                let y=a[pr*8+c] if a[pr*8+c]>=0 else -a[pr*8+c]
                if x>y:pr=r
            if pr>=k or a[pr*8+c]==0:return -1
            for j in range(k):let t=a[c*8+j];a[c*8+j]=a[pr*8+j];a[pr*8+j]=t
            let t=b[c];b[c]=b[pr];b[pr]=t
        for r in range(k):
            if r==c:continue
            let f=a[r*8+c]/a[c*8+c]
            for j in range(k):a[r*8+j]-=a[c*8+j]*f
            b[r]-=b[c]*f
    for i in range(k):
        b[i]=b[i]/a[i*8+i]
        if b[i] > 1000000.0 or b[i] < -1000000.0 or Float64(Int64(b[i]))!=b[i]:return -1
    var tmp=InlineArray[UInt8,125](fill=0);var pos=0
    tmp[0]=102;tmp[1]=40;tmp[2]=120;tmp[3]=41;tmp[4]=61;pos=5
    for i in range(k):
        if i>0:tmp[pos]=43;pos+=1
        let power=k-i-1;tmp[pos]=120;pos+=1;tmp[pos]=94;pos+=1
        if power>=10:tmp[pos]=UInt8(48+power//10);pos+=1
        tmp[pos]=UInt8(48+power%10);pos+=1;tmp[pos]=42;pos+=1
        var value=Int64(b[i])
        if b[i]<0 or (b[i]==0.0 and signbit(b[i])):tmp[pos]=45;pos+=1
        if value<0:value=-value
        var digs=InlineArray[UInt8,16](fill=0);var dc=0
        if value==0:digs[dc]=48;dc+=1
        while value>0:digs[dc]=UInt8(48+value%10);dc+=1;value//=10
        for d in range(dc):tmp[pos]=digs[dc-1-d];pos+=1
        tmp[pos]=46;tmp[pos+1]=48;pos+=2
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(pos):return -2
    for i in range(pos):out[i]=tmp[i]
    return Int64(pos)

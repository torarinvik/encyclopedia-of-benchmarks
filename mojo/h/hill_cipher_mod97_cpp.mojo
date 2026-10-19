from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("hill_cipher_mod97_cpp")
fn hill_cipher_mod97_cpp(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3:return -1
    let op=a[0];let m=a[1]
    if (op!=0 and op!=1) or m<1 or m>256 or n!=c_size_t(m+2):return -1
    let alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789~!@#$%^&*()_+`-=[]{}|;'\":,./<>?\\\r\n "
    var vals=InlineArray[Int,256](fill=0)
    for i in range(Int(m)):
        let c=a[2+i];if c<0 or c>127:return -1
        var d=-1
        for j in range(97):if Int64(alphabet[j])==c:d=j
        if d<0:return -1
        vals[i]=d
    let outlen=Int(m)+(Int(m)%2)
    if cap<c_size_t(outlen) or o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    if outlen>Int(m):vals[Int(m)]=0
    for i in range(0,outlen,2):
        let x=vals[i];let y=vals[i+1]
        let u=(if op==0:2*x+5*y else:84*x+27*y)%97
        let v=(if op==0:x+6*y else:83*x+28*y)%97
        o[i]=UInt8(alphabet[u]);o[i+1]=UInt8(alphabet[v])
    return Int64(outlen)

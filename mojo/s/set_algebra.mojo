from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn set_has(v:InlineArray[Int64,64],n:Int,x:Int64)->Bool:
    for i in range(n):if v[i]==x:return True
    return False
fn set_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int64):
    let z=bitcast[UInt64](x);for b in range(8):o[p+b]=UInt8((z>>UInt(8*b))&255)
@export("set_algebra")
fn set_algebra(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>132:return -1
    let op=a[0];let an=a[1];let bn=a[2];let key=a[3]
    if op<0 or op>8 or an<0 or an>64 or bn<0 or bn>64 or key< -1000000 or key>1000000 or n!=c_size_t(4+an+bn):return -1
    var av=InlineArray[Int64,64]();var bv=InlineArray[Int64,64]();var ac=0;var bc=0
    for i in range(Int(an)):let x=a[4+i];if x< -1000000 or x>1000000:return -1;if not set_has(av,ac,x):av[ac]=x;ac+=1
    for i in range(Int(bn)):let x=a[4+Int(an)+i];if x< -1000000 or x>1000000:return -1;if not set_has(bv,bc,x):bv[bc]=x;bc+=1
    var outv=InlineArray[Int64,128]();var oc=0
    if op<=4:
        var yes=False
        if op==0:yes=set_has(av,ac,key)
        elif op==1:yes=True;for i in range(ac):if not set_has(bv,bc,av[i]):yes=False
        elif op==2:yes=ac<bc;for i in range(ac):if not set_has(bv,bc,av[i]):yes=False
        elif op==3:yes=True;for i in range(bc):if not set_has(av,ac,bv[i]):yes=False
        else:yes=bc<ac;for i in range(bc):if not set_has(av,ac,bv[i]):yes=False
        outv[0]=1 if yes else 0;oc=1
    else:
        for i in range(ac):
            let inb=set_has(bv,bc,av[i]);if (op==5 or op==6 and inb or (op==7 or op==8) and not inb):outv[oc]=av[i];oc+=1
        if op==5 or op==8:for i in range(bc):if not set_has(av,ac,bv[i]):outv[oc]=bv[i];oc+=1
        for i in range(1,oc):let x=outv[i];var j=i;while j>0 and outv[j-1]>x:outv[j]=outv[j-1];j-=1;outv[j]=x
    let bytes=oc*8;if cap<c_size_t(bytes) or (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(oc):set_put(o,i*8,outv[i])
    return Int64(bytes)

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import floor, isfinite
comptime TRIG_PI = 3.14159265358979323846
fn trig_rounded(x:Float64,tol:Float64,kind:Int)->Float64:
    var value=x
    let period=2.0*TRIG_PI
    while value>=period:value-=period
    while value<= -period:value+=period
    var result:Float64=0.0;var previous:Float64=1.0;var step=0
    while abs(previous-result)>tol:
        previous=result
        let power=2*step+kind
        var fact:Float64=1.0;var p:Float64=1.0
        for f in range(1,power+1):fact*=Float64(f)
        for _ in range(power):p*=value
        let sign:Float64= -1.0 if step%2==1 else 1.0
        result+=sign*p/fact
        step+=1
    return floor(result*1000000.0+0.5)/1000000.0
@export("trig_functions")
fn trig_functions(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=3:return -1
    let sel=a[0];var x=a[1];let tol=a[2]
    if not isfinite(sel) or sel<0.0 or sel>7.0 or Float64(Int64(sel))!=sel or not isfinite(tol) or tol<1e-9 or tol>0.01 or (isfinite(x) and (x< -10000.0 or x>10000.0)):return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<1:return -2
    if not isfinite(x):o[0]=Float64.NaN;return 1
    let s=Int(sel)
    if s==2 or s==3 or s==6 or s==7:x=x*TRIG_PI/180.0
    var result:Float64=0.0
    if s==0 or s==2:result=trig_rounded(x,tol,1)
    elif s==1 or s==3:result=trig_rounded(x,tol,0)
    elif s==4 or s==6:
        let den=trig_rounded(x,tol,0);result=Float64.NaN if den==0.0 else trig_rounded(x,tol,1)/den
    else:
        let den=trig_rounded(x,tol,1);result=Float64.NaN if den==0.0 else trig_rounded(x,tol,0)/den
    o[0]=result
    return 1

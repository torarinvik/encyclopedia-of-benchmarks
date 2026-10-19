from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn logdec(mut out:InlineArray[UInt8,8192],mut pos:Int,value:UInt64):
    var tmp=InlineArray[UInt8,20](fill=UInt8(0));var count=0;var x=value
    while True:
        tmp[count]=UInt8(x%10);count+=1;x/=10
        if x==0:break
    while count>0:count-=1;out[pos]=UInt8(48)+tmp[count];pos+=1
@export("logarithmic_series")
fn logarithmic_series(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let xv=v[0];let terms=v[1]
    if xv < -10 or xv>10 or terms < -64 or terms>256:return -1
    if terms<=0:return 0
    let delta=xv-1;let base=UInt64(if delta<0:-delta else:delta);var staged=InlineArray[UInt8,8192](fill=UInt8(0));var pos=0
    for t in range(1,Int(terms)+1):
        let negative=if delta<0:t%2==1 else:t%2==0
        if negative:staged[pos]=UInt8(45);pos+=1
        staged[pos]=UInt8(40);pos+=1;logdec(staged,pos,base)
        # Position is advanced by the base's decimal width.
        var bx=base;var bw=1
        while bx>=10:bx/=10;bw+=1
        pos+=bw;staged[pos]=UInt8(94);pos+=1;logdec(staged,pos,UInt64(t));var tw=1;var tv=UInt64(t)
        while tv>=10:tv/=10;tw+=1
        pos+=tw;staged[pos]=UInt8(41);staged[pos+1]=UInt8(47);pos+=2;logdec(staged,pos,UInt64(t));pos+=tw;staged[pos]=UInt8(10);pos+=1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(pos):return -2
    for i in range(pos):out[i]=staged[i]
    return Int64(pos)

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
comptime OD_ROWS=17
comptime OD_WIDTH=31
comptime OD_BYTES=17*31*3
@export("one_dimensional")
fn one_dimensional(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]<0 or v[0]>11111111:return -1
    var digits=InlineArray[Int64,8](fill=0);var rules=InlineArray[Int64,8](fill=0);var x=UInt64(v[0]);var count=0
    while True:
        let d=x%10
        if d>1:return -1
        digits[count]=Int64(d);count+=1;x/=10
        if x==0:break
    for i in range(count):rules[8-count+i]=digits[count-1-i]
    var cells=InlineArray[Int64,OD_ROWS*OD_WIDTH](fill=0);cells[15]=1
    for r in range(OD_ROWS-1):
        for c in range(OD_WIDTH):
            let left=if c>0:cells[r*OD_WIDTH+c-1] else:0;let center=cells[r*OD_WIDTH+c];let right=if c+1<OD_WIDTH:cells[r*OD_WIDTH+c+1] else:0
            let pattern=Int(left*4+center*2+right)
            cells[(r+1)*OD_WIDTH+c]=rules[7-pattern]
    if cap<c_size_t(OD_BYTES) or o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    var pos=0
    for i in range(OD_ROWS*OD_WIDTH):
        let color:UInt8=if cells[i]!=0:0 else:255
        o[pos]=color;o[pos+1]=color;o[pos+2]=color;pos+=3
    return Int64(pos)

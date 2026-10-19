from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("nagel_schrekenberg")
fn nagel_schrekenberg(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>35:return -1
    let cells=a[0];let steps=a[1];let vmax=a[2]
    if cells<2 or cells>32 or steps<0 or steps>16 or vmax<0 or vmax>5 or n!=c_size_t(cells+3):return -1
    var row=InlineArray[Int64,32]()
    for i in range(Int(cells)):
        let v=a[3+i];if v< -1 or v>5:return -1;row[i]=v
    let need=Int(cells)*(Int(steps)+1)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(need):return -2
    var pos=0
    for i in range(Int(cells)):o[pos]=UInt8(row[i]+1);pos+=1
    for _ in range(Int(steps)):
        var next=InlineArray[Int64,32]();for i in range(Int(cells)):next[i]=-1
        for i in range(Int(cells)):
            if row[i]!=-1:
                var gap=0;var j=i+1
                while j<Int(cells) and row[j]==-1:gap+=1;j+=1
                if j==Int(cells):
                    j=0
                    while row[j]==-1:gap+=1;j+=1
                var speed=min(row[i]+1,vmax);speed=min(speed,Int64(gap)-1);next[i]=speed
        var moved=InlineArray[Int64,32]();for i in range(Int(cells)):moved[i]=-1
        for i in range(Int(cells)):if next[i]!=-1:moved[(i+Int(next[i]))%Int(cells)]=next[i]
        for i in range(Int(cells)):row[i]=moved[i];o[pos]=UInt8(row[i]+1);pos+=1
    return pos

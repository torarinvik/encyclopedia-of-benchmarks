from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("problem22")
fn problem22(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>100001:return -1
    let raw=input[0]
    if raw<0 or raw>6000:return -1
    let count=Int(raw);var offsets=InlineArray[Int,6000](fill=0);var lengths=InlineArray[Int,6000](fill=0);var order=InlineArray[Int,6000](fill=0);var cursor=1
    for name in range(count):
        if cursor>=Int(length):return -1
        let size=input[cursor];cursor+=1
        if size<1 or size>19 or Int(size)>Int(length)-cursor:return -1
        offsets[name]=cursor;lengths[name]=Int(size)
        for i in range(Int(size)):if input[cursor+i]<1 or input[cursor+i]>26:return -1
        cursor+=Int(size);order[name]=name
    if cursor!=Int(length):return -1
    let gaps=InlineArray[Int,8](fill=0);gaps[0]=701;gaps[1]=301;gaps[2]=132;gaps[3]=57;gaps[4]=23;gaps[5]=10;gaps[6]=4;gaps[7]=1
    for gi in range(8):
        let gap=gaps[gi]
        if gap>=count:continue
        for i in range(gap,count):
            let key=order[i];var pos=i
            while pos>=gap:
                let prev=order[pos-gap];let shared=lengths[prev] if lengths[prev]<lengths[key] else lengths[key];var cmp=0
                for j in range(shared):
                    let x=input[offsets[prev]+j];let y=input[offsets[key]+j]
                    if x<y:cmp=-1;break
                    if x>y:cmp=1;break
                if cmp==0:
                    if lengths[prev]<lengths[key]:cmp=-1
                    elif lengths[prev]>lengths[key]:cmp=1
                if cmp<=0:break
                order[pos]=prev;pos-=gap
            order[pos]=key
    var total=Int64(0)
    for pos in range(count):
        let name=order[pos];var score=Int64(0)
        for j in range(lengths[name]):score+=input[offsets[name]+j]
        total+=Int64(pos+1)*score
    return total

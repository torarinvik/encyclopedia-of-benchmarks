from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("unrolled_linked_list_benchmark")
fn unrolled_linked_list_benchmark(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>1024 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var chunks=InlineArray[Int64,2560](fill=0);var counts=InlineArray[Int,512](fill=0);var next=InlineArray[Int,512](fill=512);var blocks=0
    for i in range(Int(n)):
        let value=v[i]
        if value < -1000000 or value > 1000000:return -1
        if blocks==0:blocks=1;counts[0]=1;chunks[0]=value;continue
        let tail=blocks-1
        if counts[tail]<4:chunks[tail*5+counts[tail]]=value;counts[tail]+=1
        else:
            let keep=counts[tail]/2+1;let moved=counts[tail]-keep
            for j in range(moved):chunks[blocks*5+j]=chunks[tail*5+keep+j]
            counts[tail]=keep;chunks[blocks*5+moved]=value;counts[blocks]=moved+1;next[tail]=blocks;blocks+=1
    var total:Int64=0;var index:Int64=0;var block=0
    while block<512:
        for j in range(counts[block]):total+=(index+1)*(chunks[block*5+j]+1000000);index+=1
        if next[block]==512:break
        block=next[block]
    return total

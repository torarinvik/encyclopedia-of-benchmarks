from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("word_ladder")
fn word_ladder(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>36:return -1
    let width=a[0];let start=a[1];let target=a[2];let count=a[3]
    if width<1 or width>5 or count<0 or count>32 or n!=c_size_t(4+count):return -1
    var limit:Int64=1;for _ in range(Int(width)):limit*=26
    if start<0 or start>=limit or target<0 or target>=limit:return -1
    var words=InlineArray[Int64,32]();var wc=0;var contains=false
    for i in range(Int(count)):
        let v=a[4+i]
        if v<0 or v>=limit:return -1
        if v==target:contains=true
        var seen=false
        for j in range(wc):if words[j]==v:seen=true
        if not seen:words[wc]=v;wc+=1
    var result:Int64=0
    if contains:
        var queue=InlineArray[Int64,33]();var dist=InlineArray[Int32,33]();var visited=InlineArray[Int64,33]();var qn=1;var vn=1;queue[0]=start;dist[0]=1;visited[0]=start;var cursor=0
        while cursor<qn and result==0:
            let cur=queue[cursor];let d=dist[cursor];cursor+=1;var factor:Int64=1
            for _ in range(Int(width)):
                let digit=(cur/factor)%26
                for ch in range(26):
                    if Int64(ch)==digit:continue
                    let candidate=cur+(Int64(ch)-digit)*factor
                    if candidate==target:result=d+1;break
                    var inwords=false;for j in range(wc):if words[j]==candidate:inwords=true
                    var seen=false;for j in range(vn):if visited[j]==candidate:seen=true
                    if inwords and not seen:visited[vn]=candidate;vn+=1;queue[qn]=candidate;dist[qn]=d+1;qn+=1
                if result!=0:break
                factor*=26
        
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    let bits=bitcast[UInt64](result);for b in range(8):o[b]=UInt8((bits>>UInt(8*b))&255)
    return 8

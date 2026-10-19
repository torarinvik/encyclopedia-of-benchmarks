from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("k_medoids")
fn k_medoids(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>16:return -1
    let np=a[0];let k=a[1];let rounds=a[2]
    if np<2 or np>8 or k<1 or k>4 or k>np or rounds<1 or rounds>16 or n!=c_size_t(3+k+np):return -1
    var med=InlineArray[Int,4](fill=0);var points=InlineArray[Int64,8](fill=0);var used=InlineArray[Bool,8](fill=false)
    for i in range(Int(k)):
        let x=a[3+i];if x<0 or x>=np or used[Int(x)]:return -1
        med[i]=Int(x);used[Int(x)]=true
    for i in range(Int(np)):
        points[i]=a[3+Int(k)+i]
        if points[i]< -16 or points[i]>16:return -1
        for j in range(i):if points[j]==points[i]:return -1
    var labels=InlineArray[Int,8](fill=0)
    for iteration in range(Int(rounds)):
        for i in range(Int(np)):
            var best=0;var bd=abs(points[i]-points[med[0]])
            for slot in range(1,Int(k)):
                let d=abs(points[i]-points[med[slot]])
                if d<bd:best=slot;bd=d
            labels[i]=best
        var nextmed=InlineArray[Int,4](fill=0)
        for slot in range(Int(k)):
            var chosen=-1;var bestcost:Int64=9223372036854775807
            for i in range(Int(np)):
                if labels[i]!=slot:continue
                var cost:Int64=0
                for j in range(Int(np)):if labels[j]==slot:cost+=abs(points[i]-points[j])
                if cost<bestcost:bestcost=cost;chosen=i
            if chosen<0:return -1
            nextmed[slot]=chosen
        var same=true
        for slot in range(Int(k)):if nextmed[slot]!=med[slot]:same=false
        if same:break
        med=nextmed
    var result:Int64=0
    for slot in range(Int(k)):result|=Int64(med[slot])<<(3*slot)
    for i in range(Int(np)):result|=Int64(labels[i])<<(12+2*i)
    return result

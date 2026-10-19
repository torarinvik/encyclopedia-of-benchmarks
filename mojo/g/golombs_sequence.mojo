from std.collections import InlineArray
@export("golombs_sequence")
fn golombs_sequence(index:Int64) abi("C")->Int64:
    if index<0 or index>64:return -1
    if index==0:return 1
    if index<=2:return 2
    var queue=InlineArray[Int64,65](fill=0);queue[0]=2;var head=0;var tail=1;var generated=3
    for value in range(3,66):
        if generated>index:break
        let reps=queue[head];head+=1
        for j in range(Int(reps)):
            if generated>index:break
            queue[tail]=Int64(value);tail+=1
            if generated==index:return Int64(value)
            generated+=1
    return -1

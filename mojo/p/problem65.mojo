@export("problem65")
fn problem65(max_n:Int64) abi("C")->Int64:
    if max_n<1 or max_n>100:return -1
    var previous=InlineArray[Int32,256](fill=0);var current=InlineArray[Int32,256](fill=0);var next=InlineArray[Int32,256](fill=0)
    previous[0]=1;current[0]=2;var pl=1;var cl=1
    for i in range(2,Int(max_n+1)):
        let coefficient=Int64(2*i//3) if i%3==0 else Int64(1);var carry=Int64(0)
        for pos in range(cl):
            let old=Int64(previous[pos]) if pos<pl else Int64(0)
            let total=coefficient*Int64(current[pos])+old+carry
            next[pos]=Int32(total%10);carry=total//10
        var nl=cl
        while carry!=0:next[nl]=Int32(carry%10);nl+=1;carry//=10
        for pos in range(cl):previous[pos]=current[pos]
        for pos in range(nl):current[pos]=next[pos]
        pl=cl;cl=nl
    var sum=Int64(0)
    for i in range(cl):sum+=Int64(current[i])
    return sum

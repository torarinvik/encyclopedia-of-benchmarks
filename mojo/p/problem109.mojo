@export("problem109")
fn problem109(limit:Int64) abi("C")->Int64:
    var values=InlineArray[Int64,63](fill=0);var doubles=InlineArray[Int64,21](fill=0);var vc=0;var dc=0
    for s in range(1,21):values[vc]=Int64(s);vc+=1
    values[vc]=25;vc+=1
    for s in range(1,21):doubles[dc]=2*Int64(s);dc+=1;values[vc]=2*Int64(s);vc+=1
    doubles[dc]=50;dc+=1;values[vc]=50;vc+=1
    for s in range(1,21):values[vc]=3*Int64(s);vc+=1
    values[vc]=0;vc+=1;var count=Int64(0)
    for d in range(dc):for a in range(vc):for b in range(a,vc):if doubles[d]+values[a]+values[b]<limit:count+=1
    return count

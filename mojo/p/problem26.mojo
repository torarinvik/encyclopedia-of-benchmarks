@export("problem26")
fn problem26(digit:Int64) abi("C")->Int64:
    if digit<0 or digit>1000:return -1
    var best=Int64(1);var best_score=0
    for den in range(1,Int(digit+1)):
        var seen=InlineArray[Bool,1001](fill=False);var rem=1;var score=0;var repeat=False
        for _ in range(Int(digit)):
            if seen[rem]:repeat=True;break
            seen[rem]=True;score+=1;rem=(rem*10)%den
            if rem==0:continue
        if repeat and score>best_score:best_score=score;best=Int64(den)
    return best

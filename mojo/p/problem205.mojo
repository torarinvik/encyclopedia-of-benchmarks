fn p205_dist(sides:Int,dice:Int,inout out:InlineArray[Int64,37]):
    var cur=InlineArray[Int64,37](fill=0);var next=InlineArray[Int64,37](fill=0);cur[0]=1
    for _ in range(dice):
        for i in range(37):next[i]=0
        for total in range(37):
            if cur[total]!=0:
                for face in range(1,sides+1):next[total+face]+=cur[total]
        for i in range(37):cur[i]=next[i]
    for i in range(37):out[i]=cur[i]
@export("problem205")
fn problem205(placeholder:Int64) abi("C")->Int64:
    if placeholder!=0:return -1
    var peter=InlineArray[Int64,37](fill=0);var colin=InlineArray[Int64,37](fill=0)
    p205_dist(4,9,peter);p205_dist(6,6,colin)
    var wins=Int64(0);var below=Int64(0)
    for total in range(37):
        if total>=9:wins+=peter[total]*below
        below+=colin[total]
    let games=Int64(262144*46656);let scaled=wins*10000000
    var rounded=scaled//games;let rem=scaled%games
    if 2*rem>games or (2*rem==games and rounded%2!=0):rounded+=1
    return rounded

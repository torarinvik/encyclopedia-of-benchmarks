fn p122_solve(inout chain:InlineArray[Int64,32],length:Int,goal:Int64,depth:Int)->Bool:
    let last=chain[length-1]
    for index in range(length):
        let next=chain[index]+last
        if next==goal:return True
        if next>goal:break
        if length<depth:
            chain[length]=next
            if p122_solve(chain,length+1,goal,depth):return True
    return False
@export("problem122")
fn problem122(maximum:Int64) abi("C")->Int64:
    if maximum<0 or maximum>200:return -1
    var total=Int64(0)
    for goal_i in range(2,Int(maximum+1)):
        let goal=Int64(goal_i);var chain=InlineArray[Int64,32](fill=0);chain[0]=1;var depth=0
        while True:
            depth+=1;chain[0]=1
            if p122_solve(chain,1,goal,depth):break
        total+=Int64(depth)
    return total

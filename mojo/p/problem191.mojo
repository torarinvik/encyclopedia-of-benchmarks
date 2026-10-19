@export("problem191")
fn problem191(days:Int64) abi("C")->Int64:
    if days<0 or days>65:return -1
    var ways=InlineArray[Int64,396](fill=0)
    for absent in range(2):
        for late in range(3):ways[absent*3+late]=1
    for remaining in range(1,Int(days+1)):
        for absent in range(2):
            for late in range(3):
                let prev=(remaining-1)*6
                let late_state=ways[prev+absent*3+late+1] if late<2 else 0
                let absent_state=ways[prev+3] if absent==0 else 0
                let ontime=ways[prev+absent*3]
                ways[remaining*6+absent*3+late]=late_state+absent_state+ontime
    return ways[Int(days)*6]

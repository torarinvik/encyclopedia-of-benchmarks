@export("problem121")
fn problem121(num_turns:Int64) abi("C")->Int64:
    if num_turns<1 or num_turns>15:return -1
    var denominator=Int64(1)
    for turn in range(2,Int(num_turns+2)):denominator*=Int64(turn)
    let sequence_count=1<<Int(num_turns);var winning=Int64(0)
    for mask in range(sequence_count):
        var remaining=mask;var blue=0;var weight=Int64(1)
        for turn in range(Int(num_turns)):
            if remaining%2==0:weight*=Int64(turn+1)
            else:blue+=1
            remaining//=2
        if 2*blue>Int(num_turns):winning+=weight
    return denominator//winning

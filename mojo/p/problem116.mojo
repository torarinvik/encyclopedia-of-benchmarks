@export("problem116")
fn problem116(length:Int64) abi("C")->Int64:
    if length<0 or length>91:return -1
    var ways=InlineArray[Int64,276](fill=0)
    for row in range(Int(length+1)):
        for tile in range(2,5):
            let color=tile-2
            for start in range(0,row-tile+1):
                let suffix=row-start-tile
                ways[row*3+color]+=ways[suffix*3+color]+1
    let idx=Int(length)*3
    return ways[idx]+ways[idx+1]+ways[idx+2]

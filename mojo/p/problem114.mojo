@export("problem114")
fn problem114(length:Int64) abi("C")->Int64:
    if length<0 or length>50:return -1
    var ways=InlineArray[Int64,51](fill=1)
    for r in range(3,Int(length+1)):
        for b in range(3,r+1):
            for start in range(0,r-b):ways[r]+=ways[r-start-b-1]
            ways[r]+=1
    return ways[Int(length)]

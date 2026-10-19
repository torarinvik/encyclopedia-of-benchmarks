@export("problem117")
fn problem117(length:Int64) abi("C")->Int64:
    if length<0 or length>67:return -1
    var ways=InlineArray[Int64,68](fill=0);ways[0]=1
    for row in range(1,Int(length+1)):
        ways[row]=ways[row-1]
        if row>=2:ways[row]+=ways[row-2]
        if row>=3:ways[row]+=ways[row-3]
        if row>=4:ways[row]+=ways[row-4]
    return ways[Int(length)]

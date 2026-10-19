@export("problem115")
fn problem115(min_block_length:Int64) abi("C")->Int64:
    if min_block_length<1 or min_block_length>100:return -1
    var ways=InlineArray[Int64,1024](fill=0)
    for i in range(Int(min_block_length)):ways[i]=1
    for n in range(Int(min_block_length),1024):
        ways[n]=1
        for b in range(Int(min_block_length),n+1):
            for start in range(0,n-b):ways[n]+=ways[n-start-b-1]
            ways[n]+=1
        if ways[n]>1000000:return Int64(n)
    return -1

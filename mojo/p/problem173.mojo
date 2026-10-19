fn p173_ceil_sqrt(value:Int64)->Int64:
    if value<=0:return 0
    var root=value;var next=(root+value//root)//2
    while next<root:root=next;next=(root+value//root)//2
    return root if root*root==value else root+1
@export("problem173")
fn problem173(max_tiles:Int64) abi("C")->Int64:
    if max_tiles<0 or max_tiles>1000000:return -1
    var answer=Int64(0)
    for outer in range(3,Int(max_tiles//4+2)):
        let width=Int64(outer);let area=width*width;var hole=Int64(1)
        if area>max_tiles:
            hole=p173_ceil_sqrt(area-max_tiles)
            if hole<1:hole=1
        if (width-hole)%2!=0:hole+=1
        answer+=(width-hole-2)//2+1
    return answer

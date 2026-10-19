fn p174_ceil_sqrt(value:Int64)->Int64:
    if value<=0:return 0
    var root=value;var next=(root+value//root)//2
    while next<root:root=next;next=(root+value//root)//2
    return root if root*root==value else root+1
@export("problem174")
fn problem174(t_limit:Int64,n_limit:Int64) abi("C")->Int64:
    if t_limit>1000000:return -1
    if t_limit<0:return 0
    var count=InlineArray[UInt8,1000001](fill=0)
    for outer in range(3,Int(t_limit//4+2)):
        let width=Int64(outer);let area=width*width;var lower=Int64(1)
        if area>t_limit:
            lower=p174_ceil_sqrt(area-t_limit)
            if lower<1:lower=1
        if (width-lower)%2!=0:lower+=1
        var hole=lower
        while hole<width-1:
            let tiles=area-hole*hole
            if tiles>=0 and tiles<=t_limit:count[Int(tiles)]+=1
            hole+=2
    var answer=Int64(0)
    for tiles in range(1,Int(t_limit+1)):
        if Int64(count[tiles])>=1 and Int64(count[tiles])<=n_limit:answer+=1
    return answer

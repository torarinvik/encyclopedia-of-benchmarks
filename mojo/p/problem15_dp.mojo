@export("problem15_dp")
fn problem15_dp(grid_size:Int64) abi("C")->Int64:
    if grid_size<0 or grid_size>20:return -1
    var ways=InlineArray[Int64,441](fill=1)
    for r in range(1,Int(grid_size+1)):
        for c in range(1,Int(grid_size+1)):ways[r*21+c]=ways[(r-1)*21+c]+ways[r*21+c-1]
    return ways[Int(grid_size)*21+Int(grid_size)]

@export("problem15")
fn problem15(grid_size:Int64) abi("C")->Int64:
    if grid_size<0 or grid_size>20:return -1
    var paths=Int64(1)
    for step in range(1,Int(grid_size+1)):paths=paths*(grid_size+Int64(step))/Int64(step)
    return paths

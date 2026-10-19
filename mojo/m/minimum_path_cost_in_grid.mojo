from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("minimum_path_cost_in_grid")
fn minimum_path_cost_in_grid(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or v[0]<1 or v[0]>32 or v[1]<1 or v[1]>32:return -1
    let rows=Int(v[0]);let cols=Int(v[1]);let cells=rows*cols;let mo=2+cells
    if Int(n)!=mo+cells*cols:return -1
    for i in range(cells):if v[2+i]<0 or v[2+i]>=cells:return -1
    for i in range(cells*cols):if v[mo+i]<1 or v[mo+i]>100:return -1
    var costs=InlineArray[Int64,32](fill=0);var nxt=InlineArray[Int64,32](fill=0)
    for r in range(rows-1):
        for c in range(cols):nxt[c]=1000000000
        for c in range(cols):
            let cell=Int(v[2+r*cols+c]);let base=costs[c]+Int64(cell)
            for target in range(cols):
                let candidate=base+v[mo+cell*cols+target]
                if candidate<nxt[target]:nxt[target]=candidate
        for c in range(cols):costs[c]=nxt[c]
    let last=2+(rows-1)*cols;var best:Int64=1000000000
    for c in range(cols):
        let candidate=costs[c]+v[last+c]
        if candidate<best:best=candidate
    return best

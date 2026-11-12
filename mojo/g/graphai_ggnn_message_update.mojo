from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import exp, isfinite

comptime MAX_N = 8
comptime MAX_M = 24
comptime MAX_D = 4
comptime MAX_PARSEABLE = 453

@export("graphai_ggnn_message_update")
fn graphai_ggnn_message_update(input: UnsafePointer[Float64, ImmutAnyOrigin],
    length: c_size_t, output: UnsafePointer[Float64, MutAnyOrigin],
    capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_PARSEABLE):
        return -1
    for q in range(Int(length)):
        if not isfinite(input[q]): return -1
    let nv=input[0]; let mv=input[1]; let dv=input[2]
    if nv<1.0 or nv>Float64(MAX_N) or mv<0.0 or mv>Float64(MAX_M) or dv<1.0 or dv>Float64(MAX_D):
        return -1
    if Float64(Int(nv))!=nv or Float64(Int(mv))!=mv or Float64(Int(dv))!=dv:
        return -1
    let n=Int(nv); let m=Int(mv); let d=Int(dv)
    if Int(length)!=4+n+m+n*d+6*n*n: return -1
    let row_at=3; let col_at=row_at+n+1; let h_at=col_at+m
    let wz_at=h_at+n*d; let wr_at=wz_at+n*n; let wc_at=wr_at+n*n
    let uz_at=wc_at+n*n; let ur_at=uz_at+n*n; let uc_at=ur_at+n*n
    if input[row_at]!=0.0 or input[col_at-1]!=Float64(m): return -1
    var rows=InlineArray[Int, MAX_N+1](fill=0)
    var cols=InlineArray[Int, MAX_M](fill=0)
    for i in range(n+1):
        let x=input[row_at+i]
        if x<0.0 or x>Float64(m) or Float64(Int(x))!=x: return -1
        rows[i]=Int(x)
        if i>0 and rows[i]<rows[i-1]: return -1
    for e in range(m):
        let x=input[col_at+e]
        if x<0.0 or x>=Float64(n) or Float64(Int(x))!=x: return -1
        cols[e]=Int(x)
    for q in range(h_at, wz_at):
        if input[q] < -1.0 or input[q] > 1.0: return -1
    for q in range(wz_at, Int(length)):
        if input[q] < -0.25 or input[q] > 0.25: return -1
    let required=n*d
    if output==UnsafePointer[Float64, MutAnyOrigin]() or capacity<c_size_t(required): return -2
    var aggregate=InlineArray[Float64, MAX_N*MAX_D](fill=0.0)
    var update=InlineArray[Float64, MAX_N*MAX_D](fill=0.0)
    var reset=InlineArray[Float64, MAX_N*MAX_D](fill=0.0)
    var candidate=InlineArray[Float64, MAX_N*MAX_D](fill=0.0)
    var staged=InlineArray[Float64, MAX_N*MAX_D](fill=0.0)
    for v in range(n):
        for e in range(rows[v], rows[v+1]):
            for f in range(d): aggregate[v*d+f]+=input[h_at+cols[e]*d+f]
    for v in range(n):
        for f in range(d):
            var wz: Float64=0.0; var wr: Float64=0.0
            var uz: Float64=0.0; var ur: Float64=0.0
            for k in range(n):
                let a=v*n+k; let b=k*d+f
                wz+=input[wz_at+a]*aggregate[b]; wr+=input[wr_at+a]*aggregate[b]
                uz+=input[uz_at+a]*input[h_at+b]; ur+=input[ur_at+a]*input[h_at+b]
            let at=v*d+f
            update[at]=1.0/(1.0+exp(-(wz+uz)))
            reset[at]=1.0/(1.0+exp(-(wr+ur)))
    for v in range(n):
        for f in range(d):
            var from_graph: Float64=0.0; var from_state: Float64=0.0
            for k in range(n):
                let a=v*n+k; let b=k*d+f
                from_graph+=input[wc_at+a]*aggregate[b]
                from_state+=input[uc_at+a]*(reset[b]*input[h_at+b])
            let at=v*d+f; let x=from_graph+from_state
            candidate[at]=2.0/(1.0+exp(-2.0*x))-1.0
            staged[at]=(1.0-update[at])*input[h_at+at]+update[at]*candidate[at]
    for q in range(required): output[q]=staged[q]
    return Int64(required)

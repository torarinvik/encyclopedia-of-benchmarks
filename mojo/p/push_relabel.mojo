from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("push_relabel")
fn push_relabel(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>227:return -1
    let n64=input[0];let sc64=input[1]
    if n64<2 or n64>14 or sc64<1 or sc64>=n64:return -1
    let n=Int(n64);let sc=Int(sc64);let sink_idx=2+sc
    if Int(length)<=sink_idx:return -1
    var is_source=InlineArray[Bool,14](fill=False);var is_sink=InlineArray[Bool,14](fill=False);var sources=InlineArray[Int32,14](fill=0)
    for i in range(sc):
        let node=input[2+i]
        if node<0 or node>=n64 or is_source[Int(node)]:return -1
        is_source[Int(node)]=True;sources[i]=Int32(node)
    let sink_count64=input[sink_idx]
    if sink_count64<1 or sink_count64>n64-sc64:return -1
    let sink_count=Int(sink_count64);let matrix_start=sink_idx+1+sink_count
    if Int(length)<matrix_start or Int(length)!=matrix_start+n*n:return -1
    var sinks=InlineArray[Int32,14](fill=0)
    for i in range(sink_count):
        let node=input[sink_idx+1+i]
        if node<0 or node>=n64 or is_sink[Int(node)] or is_source[Int(node)]:return -1
        is_sink[Int(node)]=True;sinks[i]=Int32(node)
    var residual=InlineArray[Int64,256](fill=0);var source_out=InlineArray[Int64,14](fill=0);var flow_limit=Int64(0)
    for row in range(n):
        for col in range(n):
            let cap=input[matrix_start+row*n+col]
            if cap<0 or cap>1000000 or (row==col and cap!=0):return -1
            residual[row*16+col]=cap
            if is_source[row]:source_out[row]+=cap;flow_limit+=cap
    let ss=n;let tt=n+1
    for i in range(sc):
        let src=Int(sources[i]);residual[ss*16+src]=source_out[src]
    for i in range(sink_count):residual[Int(sinks[i])*16+tt]=flow_limit
    var height=InlineArray[Int32,16](fill=0);var excess=InlineArray[Int64,16](fill=0);var active=InlineArray[Bool,16](fill=False)
    height[ss]=Int32(n+2)
    for i in range(sc):
        let src=Int(sources[i]);let initial=residual[ss*16+src];residual[ss*16+src]=0;residual[src*16+ss]+=initial;excess[src]+=initial
        if excess[src]>0:active[src]=True
    while True:
        var node=0
        while node<n and !active[node]:node+=1
        if node==n:break
        active[node]=False
        while excess[node]>0:
            var pushed=False
            for neighbor in range(n+2):
                if excess[node]<=0:break
                let edge=node*16+neighbor
                if residual[edge]<=0 or height[node]!=height[neighbor]+1:continue
                let amount=excess[node] if excess[node]<residual[edge] else residual[edge]
                residual[edge]-=amount;residual[neighbor*16+node]+=amount;excess[node]-=amount
                let previous=excess[neighbor];excess[neighbor]+=amount
                if neighbor<n and previous==0:active[neighbor]=True
                pushed=True
            if excess[node]>0 and !pushed:
                var minimum=1000
                for neighbor in range(n+2):
                    if residual[node*16+neighbor]>0 and height[neighbor]<minimum:minimum=Int(height[neighbor])
                if minimum==1000:return -1
                height[node]=Int32(minimum+1)
    return excess[tt]

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import abs
alias QN=3073
fn qt_contains(node:Int,x:Float64,y:Float64,cx:InlineArray[Float64,QN],cy:InlineArray[Float64,QN],hw:InlineArray[Float64,QN])->Bool:
    return x>=cx[node]-hw[node] and x<=cx[node]+hw[node] and y>=cy[node]-hw[node] and y<=cy[node]+hw[node]
fn qt_subdivide(node:Int,mut node_count:Int,mut cx:InlineArray[Float64,QN],mut cy:InlineArray[Float64,QN],mut hw:InlineArray[Float64,QN],mut child_count:InlineArray[Int64,QN],mut child:InlineArray[Int64,12292],mut divided:InlineArray[Bool,QN]):
    let ch=hw[node]/2.0;let base=node_count
    for k in range(4):
        let idx=base+k;child[4*node+k]=idx
        hw[idx]=ch
        if k==0 or k==2:cx[idx]=cx[node]-ch
        else:cx[idx]=cx[node]+ch
        if k==0 or k==1:cy[idx]=cy[node]+ch
        else:cy[idx]=cy[node]-ch
    node_count+=4;divided[node]=True
fn qt_insert(node:Int,p:Int,capacity:Int,mut node_count:Int,px:InlineArray[Float64,64],py:InlineArray[Float64,64],mut cx:InlineArray[Float64,QN],mut cy:InlineArray[Float64,QN],mut hw:InlineArray[Float64,QN],mut local_count:InlineArray[Int64,QN],mut local_points:InlineArray[Int64,24584],mut child:InlineArray[Int64,12292],mut divided:InlineArray[Bool,QN])->Bool:
    if not qt_contains(node,px[p],py[p],cx,cy,hw):return False
    if local_count[node]<capacity:
        local_points[node*8+Int(local_count[node])]=p;local_count[node]+=1;return True
    if not divided[node]:qt_subdivide(node,node_count,cx,cy,hw,local_count,child,divided)
    for k in range(4):
        if qt_insert(Int(child[node*4+k]),p,capacity,node_count,px,py,cx,cy,hw,local_count,local_points,child,divided):return True
    return False
fn qt_intersects(node:Int,qx:Float64,qy:Float64,qh:Float64,cx:InlineArray[Float64,QN],cy:InlineArray[Float64,QN],hw:InlineArray[Float64,QN])->Bool:
    return qx-qh<=cx[node]+hw[node] and qx+qh>=cx[node]-hw[node] and qy-qh<=cy[node]+hw[node] and qy+qh>=cy[node]-hw[node]
fn qt_query(node:Int,qx:Float64,qy:Float64,qh:Float64,px:InlineArray[Float64,64],py:InlineArray[Float64,64],cx:InlineArray[Float64,QN],cy:InlineArray[Float64,QN],hw:InlineArray[Float64,QN],local_count:InlineArray[Int64,QN],local_points:InlineArray[Int64,24584],child:InlineArray[Int64,12292],divided:InlineArray[Bool,QN],mut result:InlineArray[Int64,64],mut count:Int):
    if not qt_intersects(node,qx,qy,qh,cx,cy,hw):return
    let left=qx-qh;let right=qx+qh;let bottom=qy-qh;let top=qy+qh
    for i in range(Int(local_count[node])):
        let p=Int(local_points[node*8+i])
        if px[p]>=left and px[p]<=right and py[p]>=bottom and py[p]<=top:result[count]=p;count+=1
    if divided[node]:
        for k in range(4):qt_query(Int(child[node*4+k]),qx,qy,qh,px,py,cx,cy,hw,local_count,local_points,child,divided,result,count)
@export("quad_tree")
fn quad_tree(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<8 or n>137:return -1
    let rootx=a[0];let rooty=a[1];let rootw=a[2];let capacity=a[3];let count=a[4]
    if rootx< -2048 or rootx>2048 or rooty< -2048 or rooty>2048 or rootw<1 or rootw>1024 or capacity<1 or capacity>8 or count<0 or count>64 or n!=c_size_t(8+2*count):return -1
    let qo=5+2*Int(count);let qx=a[qo];let qy=a[qo+1];let qh=a[qo+2]
    if qx< -8192 or qx>8192 or qy< -8192 or qy>8192 or qh<0 or qh>8192:return -1
    var px=InlineArray[Float64,64]();var py=InlineArray[Float64,64]()
    for i in range(Int(count)):
        let x=a[5+2*i];let y=a[6+2*i]
        if x< -8192 or x>8192 or y< -8192 or y>8192:return -1
        for j in range(i):if a[5+2*j]==x and a[6+2*j]==y:return -1
        px[i]=Float64(x);py[i]=Float64(y)
    var cx=InlineArray[Float64,QN]();var cy=InlineArray[Float64,QN]();var hw=InlineArray[Float64,QN]();var local_count=InlineArray[Int64,QN]();var local_points=InlineArray[Int64,24584]();var child=InlineArray[Int64,12292]();var divided=InlineArray[Bool,QN](fill=False);var node_count=1
    cx[0]=Float64(rootx);cy[0]=Float64(rooty);hw[0]=Float64(rootw)
    var flags=InlineArray[Int64,64]();var results=InlineArray[Int64,64]();var result_count=0
    for i in range(Int(count)):flags[i]=1 if qt_insert(0,i,Int(capacity),node_count,px,py,cx,cy,hw,local_count,local_points,child,divided) else 0
    qt_query(0,Float64(qx),Float64(qy),Float64(qh),px,py,cx,cy,hw,local_count,local_points,child,divided,results,result_count)
    let words=2+Int(count)+2*result_count;let bytes=words*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var staged=InlineArray[Int64,194]();staged[0]=count
    for i in range(Int(count)):staged[i+1]=flags[i]
    staged[1+Int(count)]=result_count
    for i in range(result_count):let p=Int(results[i]);staged[2+Int(count)+2*i]=Int64(px[p]);staged[3+Int(count)+2*i]=Int64(py[p])
    for i in range(words):
        let bits=bitcast[UInt64](staged[i])
        for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)

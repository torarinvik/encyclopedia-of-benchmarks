from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn trim_valid(a:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,node:Int,lo:Int64,hi:Int64,inout seen:InlineArray[Bool,100],inout count:Int)->Bool:
    if node<0:return True
    if node>=n or seen[node]:return False
    let value=a[node*3]
    if value<=lo or value>=hi:return False
    seen[node]=True;count+=1
    let l=Int(a[node*3+1]);let r=Int(a[node*3+2])
    if l< -1 or r< -1:return False
    return trim_valid(a,n,l,lo,value,seen,count) and trim_valid(a,n,r,value,hi,seen,count)
fn trim_build(a:UnsafePointer[Int64,ImmutAnyOrigin],node:Int,low:Int64,high:Int64,inout out:InlineArray[Int64,301],inout used:Int)->Int64:
    if node<0:return -1
    let val=a[node*3];let left=Int(a[node*3+1]);let right=Int(a[node*3+2])
    if val<low:return trim_build(a,right,low,high,out,used)
    if val>high:return trim_build(a,left,low,high,out,used)
    let idx=used;used+=1;let at=1+idx*3
    out[at]=val;out[at+1]= -1;out[at+2]= -1
    out[at+1]=trim_build(a,left,low,high,out,used);out[at+2]=trim_build(a,right,low,high,out,used)
    return Int64(idx)
@export("trim_bst")
fn trim_bst(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,root:Int64,low:Int64,high:Int64,o:UnsafePointer[Int64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>100 or low<1 or high>10000 or low>high:return -1
    if n==0:
        if root!= -1:return -1
        if o==UnsafePointer[Int64,MutAnyOrigin]() or cap<1:return -2
        o[0]= -1;return 1
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or root<0 or root>=Int64(n):return -1
    var parents=InlineArray[Int32,100]();var seen=InlineArray[Bool,100]();var visited=0
    for i in range(Int(n)):
        let v=a[i*3];let l=a[i*3+1];let r=a[i*3+2]
        if v<1 or v>10000 or l< -1 or l>=Int64(n) or r< -1 or r>=Int64(n):return -1
        if l>=0:parents[Int(l)]+=1
        if r>=0:parents[Int(r)]+=1
        if (l>=0 and parents[Int(l)]>1) or (r>=0 and parents[Int(r)]>1):return -1
    for i in range(Int(n)):
        if (i==Int(root) and parents[i]!=0) or (i!=Int(root) and parents[i]!=1):return -1
    if not trim_valid(a,Int(n),Int(root),0,10001,seen,visited) or visited!=Int(n):return -1
    if o==UnsafePointer[Int64,MutAnyOrigin]() or cap<c_size_t(1+3*Int(n)):return -2
    var staged=InlineArray[Int64,301]();var used=0
    staged[0]=trim_build(a,Int(root),low,high,staged,used)
    for i in range(1+used*3):o[i]=staged[i]
    return Int64(1+used*3)

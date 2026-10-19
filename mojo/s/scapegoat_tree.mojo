from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sg_size(l:UnsafePointer[Int32,MutAnyOrigin],r:UnsafePointer[Int32,MutAnyOrigin],root:Int)->Int:
    if root<0:return 0
    return 1+sg_size(l,r,Int(l[root]))+sg_size(l,r,Int(r[root]))
fn sg_height(l:UnsafePointer[Int32,MutAnyOrigin],r:UnsafePointer[Int32,MutAnyOrigin],root:Int)->Int:
    var n=sg_size(l,r,root);var h=0
    while n>1:n=n/2;h+=1
    return h
fn sg_flat(l:UnsafePointer[Int32,MutAnyOrigin],r:UnsafePointer[Int32,MutAnyOrigin],root:Int,order:UnsafePointer[Int32,MutAnyOrigin],pos:UnsafePointer[Int32,MutAnyOrigin]):
    if root<0:return
    sg_flat(l,r,Int(l[root]),order,pos);order[pos[0]]=Int32(root);pos[0]+=1;sg_flat(l,r,Int(r[root]),order,pos)
fn sg_rebuild(l:UnsafePointer[Int32,MutAnyOrigin],r:UnsafePointer[Int32,MutAnyOrigin],order:UnsafePointer[Int32,MutAnyOrigin],lo:Int,hi:Int)->Int:
    if lo>=hi:return -1
    let mid=(lo+hi)/2;let root=Int(order[mid]);l[root]=Int32(sg_rebuild(l,r,order,lo,mid));r[root]=Int32(sg_rebuild(l,r,order,mid+1,hi));return root
fn sg_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,v:Int64):
    let bits=bitcast[UInt64](v)
    for b in range(8):o[p+b]=UInt8((bits>>UInt(8*b))&255)
@export("scapegoat_tree")
fn scapegoat_tree(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>130:return -1
    let count=a[0];if count<0 or count>64 or n!=c_size_t(1+2*count):return -1
    var distinct=InlineArray[Int64,32]();var dn=0
    for i in range(Int(count)):
        let op=a[1+2*i];let key=a[2+2*i]
        if op<0 or op>6 or key< -2147483648 or key>2147483647 or (op>=3 and key!=0):return -1
        if op==0:
            var found=False
            for j in range(dn):if distinct[j]==key:found=True
            if not found:if dn>=32:return -1;distinct[dn]=key;dn+=1
        elif op==2:
            for j in range(dn):if distinct[j]==key:for k in range(j,dn-1):distinct[k]=distinct[k+1];dn-=1;break
        elif op==6:dn=0
    var keys=InlineArray[Int64,32]();var left=InlineArray[Int32,32]();var right=InlineArray[Int32,32]();var active=InlineArray[Bool,32]()
    for i in range(32):left[i]= -1;right[i]= -1
    var root= -1;var size=0;var maxsize=0;var results=InlineArray[Int64,64]()
    for opi in range(Int(count)):
        let op=a[1+2*opi];let key=a[2+2*opi]
        if op==0:
            var cur=root;var parent= -1;var path=InlineArray[Int32,32]();var plen=0
            while cur>=0 and keys[cur]!=key:
                parent=cur;path[plen]=Int32(cur);plen+=1;cur=Int(left[cur] if key<keys[cur] else right[cur])
            if cur>=0:results[opi]=0
            else:
                var id=0
                while id<32 and active[id]:id+=1
                active[id]=True;keys[id]=key;left[id]= -1;right[id]= -1
                if parent<0:root=id
                elif key<keys[parent]:left[parent]=Int32(id)
                else:right[parent]=Int32(id)
                size+=1;if size>maxsize:maxsize=size
                if plen>sg_height(left.unsafe_ptr(),right.unsafe_ptr(),root):
                    var depth=1;var scap= -1;var par= -1
                    while plen>0:
                        plen-=1;let cand=Int(path[plen])
                        if depth>sg_height(left.unsafe_ptr(),right.unsafe_ptr(),cand):
                            scap=cand
                            if plen>0:plen-=1;par=Int(path[plen])
                            break
                        depth+=1
                    var order=InlineArray[Int32,32]();var pos=InlineArray[Int32,1]();sg_flat(left.unsafe_ptr(),right.unsafe_ptr(),scap,order.unsafe_ptr(),pos.unsafe_ptr())
                    let rebuilt=sg_rebuild(left.unsafe_ptr(),right.unsafe_ptr(),order.unsafe_ptr(),0,Int(pos[0]))
                    if par<0:root=rebuilt
                    elif keys[par]<keys[rebuilt]:right[par]=Int32(rebuilt)
                    else:left[par]=Int32(rebuilt)
                results[opi]=1
        elif op==1:
            var cur=root
            while cur>=0 and keys[cur]!=key:cur=Int(left[cur] if key<keys[cur] else right[cur])
            results[opi]=1 if cur>=0 else 0
        elif op==2:
            var cur=root;var par= -1
            while cur>=0 and keys[cur]!=key:par=cur;cur=Int(left[cur] if key<keys[cur] else right[cur])
            if cur<0:results[opi]=0
            else:
                if left[cur]>=0 and right[cur]>=0:
                    var pp=cur;var pred=Int(left[cur])
                    while right[pred]>=0:pp=pred;pred=Int(right[pred])
                    keys[cur]=keys[pred];let repl=left[pred]
                    if pp==cur:left[cur]=repl
                    else:right[pp]=repl
                    active[pred]=False;left[pred]= -1;right[pred]= -1
                else:
                    let repl=Int(left[cur] if left[cur]>=0 else right[cur])
                    if par<0:root=repl
                    elif left[par]==cur:left[par]=Int32(repl)
                    else:right[par]=Int32(repl)
                    active[cur]=False;left[cur]= -1;right[cur]= -1
                size-=1
                if root>=0 and 2*size<maxsize:
                    var order=InlineArray[Int32,32]();var pos=InlineArray[Int32,1]();sg_flat(left.unsafe_ptr(),right.unsafe_ptr(),root,order.unsafe_ptr(),pos.unsafe_ptr());root=sg_rebuild(left.unsafe_ptr(),right.unsafe_ptr(),order.unsafe_ptr(),0,Int(pos[0]));maxsize=size
                results[opi]=1
        elif op==3:results[opi]=Int64(size)
        elif op==4:results[opi]=Int64(maxsize)
        elif op==5:
            if root<0:results[opi]=1
            else:let total=sg_size(left.unsafe_ptr(),right.unsafe_ptr(),root);results[opi]=1 if 2*sg_size(left.unsafe_ptr(),right.unsafe_ptr(),Int(left[root]))<=total and 2*sg_size(left.unsafe_ptr(),right.unsafe_ptr(),Int(right[root]))<=total else 0
        else:
            for i in range(32):active[i]=False;left[i]= -1;right[i]= -1
            root= -1;size=0;maxsize=0;results[opi]= -2
    let bytes=(2+Int(count)+size)*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    sg_put(o,0,count);for i in range(Int(count)):sg_put(o,(i+1)*8,results[i]);sg_put(o,(Int(count)+1)*8,Int64(size))
    var order=InlineArray[Int32,32]();var pos=InlineArray[Int32,1]();sg_flat(left.unsafe_ptr(),right.unsafe_ptr(),root,order.unsafe_ptr(),pos.unsafe_ptr())
    for i in range(size):sg_put(o,(Int(count)+2+i)*8,keys[order[i]])
    return Int64(bytes)

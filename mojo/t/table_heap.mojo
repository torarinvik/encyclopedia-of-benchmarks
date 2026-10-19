from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
alias NIL= -9223372036854775808
fn th_hash(key:Int64)->Int:
    return Int(bitcast[UInt32](Int32(key))%128)
fn th_find(keys:InlineArray[Int64,128],state:InlineArray[Int64,128],key:Int64)->Int:
    let start=th_hash(key)
    for probe in range(128):
        let i=(start+probe)%128
        if state[i]==0:return -1
        if state[i]==1 and keys[i]==key:return i
    return -1
fn th_store(mut keys:InlineArray[Int64,128],mut pri:InlineArray[Int64,128],mut idx:InlineArray[Int64,128],mut state:InlineArray[Int64,128],key:Int64,p:Int64,position:Int):
    let start=th_hash(key);var tomb= -1
    for probe in range(128):
        let i=(start+probe)%128
        if state[i]==1 and keys[i]==key:keys[i]=key;pri[i]=p;idx[i]=position;return
        if state[i]==2 and tomb<0:tomb=i
        if state[i]==0:
            let at=tomb if tomb>=0 else i;state[at]=1;keys[at]=key;pri[at]=p;idx[at]=position;return
    if tomb>=0:state[tomb]=1;keys[tomb]=key;pri[tomb]=p;idx[tomb]=position
fn th_delete(mut state:InlineArray[Int64,128],slot:Int):state[slot]=2
fn th_swap(mut heap:InlineArray[Int64,64],mut keys:InlineArray[Int64,128],mut pri:InlineArray[Int64,128],mut idx:InlineArray[Int64,128],mut state:InlineArray[Int64,128],a:Int,b:Int,update:Bool):
    let t=heap[a];heap[a]=heap[b];heap[b]=t
    if update:
        let sa=th_find(keys,state,heap[a]);let sb=th_find(keys,state,heap[b])
        idx[sa]=a;idx[sb]=b
fn th_up(mut heap:InlineArray[Int64,64],mut keys:InlineArray[Int64,128],mut pri:InlineArray[Int64,128],mut idx:InlineArray[Int64,128],mut state:InlineArray[Int64,128],position:Int):
    var i=position
    while i>0:
        let parent=(i-1)/2;let si=th_find(keys,state,heap[i]);let sp=th_find(keys,state,heap[parent])
        if pri[si]>=pri[sp]:return
        th_swap(heap,keys,pri,idx,state,i,parent,True);i=parent
fn th_down(mut heap:InlineArray[Int64,64],count:Int,mut keys:InlineArray[Int64,128],mut pri:InlineArray[Int64,128],mut idx:InlineArray[Int64,128],mut state:InlineArray[Int64,128],position:Int,update:Bool):
    var i=position
    while True:
        let left=2*i+1
        if left>=count:return
        var child=left+1
        if child>=count or pri[th_find(keys,state,heap[left])]<pri[th_find(keys,state,heap[child])]:child=left
        if pri[th_find(keys,state,heap[child])]>=pri[th_find(keys,state,heap[i])]:return
        th_swap(heap,keys,pri,idx,state,i,child,update);i=child
@export("table_heap")
fn table_heap(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1155:return -1
    let initial=a[0]
    if initial<0 or initial>64:return -1
    let opidx=1+2*Int(initial)
    if n<=c_size_t(opidx):return -1
    let ops=a[opidx]
    if ops<0 or ops>256 or n!=c_size_t(2+2*initial+4*ops) or n>1154:return -1
    var heap=InlineArray[Int64,64]();var keys=InlineArray[Int64,128]();var pri=InlineArray[Int64,128]();var idx=InlineArray[Int64,128]();var state=InlineArray[Int64,128]();var count=Int(initial)
    for i in range(count):
        let id=a[1+2*i];let p=a[2+2*i]
        if id< -2147483648 or id>2147483647 or p< -2147483648 or p>2147483647 or th_find(keys,state,id)>=0:return -1
        heap[i]=id;th_store(keys,pri,idx,state,id,p,0)
    for parent in range(count/2):th_down(heap,count,keys,pri,idx,state,count/2-1-parent,False)
    for i in range(count):idx[th_find(keys,state,heap[i])]=i
    var answers=InlineArray[Int64,256]();var cur=opidx+1
    for oi in range(Int(ops)):
        let op=a[cur];let x=a[cur+1];let y=a[cur+2];let z=a[cur+3];cur+=4
        if op<0 or op>9:return -1
        if op==0:
            if x< -2147483648 or x>2147483647 or y< -2147483648 or y>2147483647 or z!=0 or count>=64 or th_find(keys,state,x)>=0:return -1
            heap[count]=x;th_store(keys,pri,idx,state,x,y,count);count+=1;th_up(heap,keys,pri,idx,state,count-1);answers[oi]=NIL
        elif op==1:
            if x!=0 or y!=0 or z!=0:return -1
            answers[oi]=NIL if count==0 else heap[0]
        elif op==2:
            if x!=0 or y!=0 or z!=0 or count==0:return -1
            let removed=heap[0];answers[oi]=removed;th_swap(heap,keys,pri,idx,state,0,count-1,True);count-=1;th_delete(state,th_find(keys,state,removed))
            if count>0:th_down(heap,count,keys,pri,idx,state,0,True)
        elif op==3 or op==4:
            if x!=0 or y!=0 or z!=0:return -1
            answers[oi]=count if op==3 else (1 if count==0 else 0)
        elif op==5:
            if x< -2147483648 or x>2147483647 or y!=0 or z!=0:return -1
            let slot=th_find(keys,state,x);answers[oi]=NIL if slot<0 else idx[slot]+1
        elif op==6 or op==7:
            if x< -2147483648 or x>2147483647 or y< -2147483648 or y>2147483647 or z!=0:return -1
            let slot=th_find(keys,state,x)
            if slot<0 or (op==6 and y>pri[slot]) or (op==7 and y<pri[slot]):return -1
            let pos=Int(idx[slot]);pri[slot]=y
            if op==6:th_up(heap,keys,pri,idx,state,pos)
            else:th_down(heap,count,keys,pri,idx,state,pos,True)
            answers[oi]=NIL
        elif op==8:
            if x< -2147483648 or x>2147483647 or y< -2147483648 or y>2147483647 or z< -2147483648 or z>2147483647:return -1
            let oldslot=th_find(keys,state,x);if oldslot<0:return -1
            let pos=Int(idx[oldslot]);let oldp=pri[oldslot];let newslot=th_find(keys,state,y)
            if newslot>=0:
                if y!=x or z!=oldp:return -1
            else:
                th_delete(state,oldslot);heap[pos]=y;th_store(keys,pri,idx,state,y,z,pos)
                if z<oldp:th_up(heap,keys,pri,idx,state,pos)
                else:th_down(heap,count,keys,pri,idx,state,pos,True)
            answers[oi]=NIL
        else:
            if x< -2147483648 or x>2147483647 or y!=0 or z!=0:return -1
            let slot=th_find(keys,state,x);if slot<0:return -1
            let pos=Int(idx[slot]);let oldp=pri[slot];count-=1
            if pos!=count:
                heap[pos]=heap[count];idx[th_find(keys,state,heap[pos])]=pos
                if pri[th_find(keys,state,heap[pos])]<oldp:th_up(heap,keys,pri,idx,state,pos)
                else:th_down(heap,count,keys,pri,idx,state,pos,True)
            th_delete(state,slot);answers[oi]=NIL
    let bytes=Int(ops)*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(Int(ops)):let bits=bitcast[UInt64](answers[i]);for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn ghp_hash(h0:UInt64,val:Int64)->UInt64:
    var h=h0;let x=bitcast[UInt64](val)
    for i in range(8):h=(h^((x>>UInt64(8*i))&255))*UInt64(0x100000001b3)
    return h
fn ghp_swap(mut ids:InlineArray[Int64,128],mut pri:InlineArray[Int64,128],mut pos:InlineArray[Int,4096],i:Int,j:Int):
    let ti=ids[i];ids[i]=ids[j];ids[j]=ti;let tp=pri[i];pri[i]=pri[j];pri[j]=tp;pos[ids[i]]=i;pos[ids[j]]=j
@export("generic_heap")
fn generic_heap(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>769 or v[0]<0 or v[0]>256 or n!=c_size_t(1+3*v[0]):return -1
    var ids=InlineArray[Int64,128](fill=0);var pri=InlineArray[Int64,128](fill=0);var pos=InlineArray[Int,4096](fill= -1);var size=0;var hash=UInt64(0xcbf29ce484222325)
    for k in range(Int(v[0])):
        let op=v[1+3*k];let item=v[2+3*k];let priority=v[3+3*k]
        if op==0:
            if item<0 or item>=4096 or priority< -2147483648 or priority>2147483647 or pos[Int(item)]>=0 or size>=128:return -1
            var i=size;size+=1;ids[i]=item;pri[i]=priority;pos[Int(item)]=i
            while i>0:
                let parent=(i-1)//2
                if pri[i]<=pri[parent]:break
                ghp_swap(ids,pri,pos,i,parent);i=parent
        elif op==1 or op==2:
            if item!=0 or priority!=0 or size==0:return -1
            let rid=ids[0];let rp=pri[0]
            if op==2:
                ghp_swap(ids,pri,pos,0,size-1);size-=1;pos[Int(rid)]= -1;var i=0
                while 2*i+1<size:
                    var child=2*i+1
                    if child+1<size and pri[child+1]>pri[child]:child+=1
                    if pri[i]>=pri[child]:break
                    ghp_swap(ids,pri,pos,i,child);i=child
            hash=ghp_hash(ghp_hash(hash,rid),rp)
        elif op==3:
            if item<0 or item>=4096 or priority< -2147483648 or priority>2147483647 or pos[Int(item)]<0:return -1
            var i=pos[Int(item)];pri[i]=priority
            while i>0:
                let parent=(i-1)//2
                if pri[i]<=pri[parent]:break
                ghp_swap(ids,pri,pos,i,parent);i=parent
        elif op==4 or op==5:
            if item!=0 or priority!=0:return -1
            hash=ghp_hash(hash,Int64(size) if op==4 else (1 if size==0 else 0))
        else:return -1
    return bitcast[Int64](hash)

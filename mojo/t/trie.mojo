from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime TR_MAX=1026
comptime TR_MOD=1000000007
@export("trie_benchmark")
fn trie_benchmark(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>1024 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var child=InlineArray[Int32,TR_MAX*26]();var terminal=InlineArray[Bool,TR_MAX]();var subtree=InlineArray[Int32,TR_MAX]();var hashes=InlineArray[Int64,TR_MAX]()
    var used=1;var pos=0;var ops=0;var checksum:Int64=0;var hash_sum:Int64=0
    while pos<Int(n):
        if pos+1>=Int(n) or ops>=512:return -1
        let op=a[pos];let wl=a[pos+1]
        if op<0 or op>5 or wl<0 or wl>128 or (op==5 and wl!=0) or wl>Int64(Int(n-pos-2)):return -1
        var wh=wl+1
        for i in range(Int(wl)):
            let ch=a[pos+2+i]
            if ch<97 or ch>122:return -1
            wh=(wh*31+ch-96)%TR_MOD
        var node=1;var observed:Int64=0
        if op==0:
            for i in range(Int(wl)):
                let letter=Int(a[pos+2+i]-97);let edge=(node-1)*26+letter
                if child[edge]==0:
                    if used>=TR_MAX:return -1
                    used+=1;child[edge]=Int32(used);hashes[used]=wh
                node=Int(child[edge])
            if not terminal[node]:
                terminal[node]=True;hash_sum=(hash_sum+wh)%TR_MOD
                node=1;subtree[node]+=1
                for i in range(Int(wl)):
                    node=Int(child[(node-1)*26+Int(a[pos+2+i]-97)]);subtree[node]+=1
                observed=1
        else:
            var traversed=0
            while traversed<Int(wl):
                if node==0:break
                node=Int(child[(node-1)*26+Int(a[pos+2+traversed]-97)]);traversed+=1
            if traversed<Int(wl):node=0
            if op==1:
                if node>0 and terminal[node]:
                    terminal[node]=False;hash_sum=(hash_sum-hashes[node]+TR_MOD)%TR_MOD;observed=1
                    node=1;subtree[node]-=1
                    for i in range(Int(wl)):node=Int(child[(node-1)*26+Int(a[pos+2+i]-97)]);subtree[node]-=1
            elif op==2:observed=1 if node>0 and terminal[node] else 0
            elif op==3:observed=1 if node>0 and subtree[node]>0 else 0
            elif op==4:observed=Int64(subtree[node]) if node>0 else 0
            else:observed=Int64(subtree[1])
        checksum+=(Int64(ops)+1)*(observed+1000000);ops+=1;pos+=2+Int(wl)
    return checksum+(Int64(ops)+1)*(hash_sum+1000000)

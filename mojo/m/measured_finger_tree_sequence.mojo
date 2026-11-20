from std.collections import InlineArray, List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MFT_Q = 32
comptime MFT_ROOTS = 65
comptime MFT_ARENA = 16384
comptime MFT_NODE_BASE = 8192
comptime MFT_MAX_INPUT = 194
comptime MFT_MAX_PARSEABLE = 195
comptime MFT_MAX_OUTPUT = 1792
comptime MFT_MAX_SUM: Int64 = 64000000

struct MFTree:
    var kind: Int32
    var level: Int32
    var plen: Int32
    var slen: Int32
    var mid: Int32
    var p0: Int32
    var p1: Int32
    var p2: Int32
    var p3: Int32
    var s0: Int32
    var s1: Int32
    var s2: Int32
    var s3: Int32
    var count: Int32
    var sum: Int64

    fn __init__(out self, kind: Int, level: Int, plen: Int, slen: Int, mid: Int,
                p0: Int, p1: Int, p2: Int, p3: Int, s0: Int, s1: Int, s2: Int, s3: Int,
                count: Int, sum: Int64):
        self.kind=Int32(kind); self.level=Int32(level); self.plen=Int32(plen); self.slen=Int32(slen); self.mid=Int32(mid)
        self.p0=Int32(p0); self.p1=Int32(p1); self.p2=Int32(p2); self.p3=Int32(p3)
        self.s0=Int32(s0); self.s1=Int32(s1); self.s2=Int32(s2); self.s3=Int32(s3); self.count=Int32(count); self.sum=sum

struct MFNode:
    var level: Int32
    var arity: Int32
    var c0: Int32
    var c1: Int32
    var c2: Int32
    var count: Int32
    var sum: Int64
    fn __init__(out self, level: Int, arity: Int, c0: Int, c1: Int, c2: Int, count: Int, sum: Int64):
        self.level=Int32(level); self.arity=Int32(arity); self.c0=Int32(c0); self.c1=Int32(c1); self.c2=Int32(c2); self.count=Int32(count); self.sum=sum

struct MFRoot:
    var tree: Int
    var length: Int
    var sum: Int64
    fn __init__(out self, tree: Int, length: Int, sum: Int64):
        self.tree=tree; self.length=length; self.sum=sum

struct MFMeasure:
    var count: Int
    var sum: Int64
    fn __init__(out self, count: Int, sum: Int64):
        self.count=count; self.sum=sum

struct MFView:
    var found: Bool
    var item: Int
    var tree: Int
    fn __init__(out self, found: Bool, item: Int, tree: Int):
        self.found=found; self.item=item; self.tree=tree

struct MFSplit:
    var found: Bool
    var item: Int
    var left: Int
    var right: Int
    fn __init__(out self, found: Bool, item: Int, left: Int, right: Int):
        self.found=found; self.item=item; self.left=left; self.right=right

struct MFContext:
    var trees: List[MFTree]
    var nodes: List[MFNode]
    var failed: Bool
    var empty_ids: InlineArray[Int, 16]
    var empty_ready: InlineArray[Bool, 16]
    fn __init__(out self):
        self.trees=List[MFTree](capacity=MFT_NODE_BASE); self.nodes=List[MFNode](capacity=MFT_NODE_BASE); self.failed=False
        self.empty_ids=InlineArray[Int,16](); self.empty_ready=InlineArray[Bool,16](fill=False)

fn mt_pre(t: MFTree, i: Int) -> Int:
    if i==0: return Int(t.p0)
    if i==1: return Int(t.p1)
    if i==2: return Int(t.p2)
    return Int(t.p3)
fn mt_suf(t: MFTree, i: Int) -> Int:
    if i==0: return Int(t.s0)
    if i==1: return Int(t.s1)
    if i==2: return Int(t.s2)
    return Int(t.s3)
fn mt_node_child(n: MFNode, i: Int) -> Int:
    if i==0: return Int(n.c0)
    if i==1: return Int(n.c1)
    return Int(n.c2)

fn mf_tree(c: MFContext, id: Int) -> MFTree: return c.trees[id]
fn mf_measure_ref(c: MFContext, r: Int) -> MFMeasure:
    if r<0: return MFMeasure(1,Int64(-r-1))
    let n=c.nodes[r-MFT_NODE_BASE]; return MFMeasure(Int(n.count),n.sum)
fn mf_add(a: MFMeasure,b: MFMeasure) -> MFMeasure: return MFMeasure(a.count+b.count,a.sum+b.sum)
fn mf_measure_tree(c: MFContext,id: Int) -> MFMeasure:
    let t=c.trees[id]; return MFMeasure(Int(t.count),t.sum)
fn mf_empty(mut c: MFContext,level: Int) -> Int:
    if level<0 or level>=16: c.failed=True; return 0
    if c.empty_ready[level]: return c.empty_ids[level]
    let id=c.trees.size()
    if id+c.nodes.size()>=MFT_ARENA or id>=MFT_NODE_BASE: c.failed=True; return 0
    c.trees.append(MFTree(0,level,0,0,-1,0,0,0,0,0,0,0,0,0,0))
    c.empty_ids[level]=id; c.empty_ready[level]=True; return id
fn mf_node(mut c: MFContext,level: Int,items: InlineArray[Int,4],n: Int) -> Int:
    if c.trees.size()+c.nodes.size()>=MFT_ARENA or c.nodes.size()>=MFT_NODE_BASE: c.failed=True; return MFT_NODE_BASE
    var count=0; var sum=Int64(0)
    for i in range(n):
        let m=mf_measure_ref(c,items[i])
        count+=m.count
        sum+=m.sum
    let a=items[0]; let b=items[1] if n>1 else 0; let d=items[2] if n>2 else 0
    let id=c.nodes.size(); c.nodes.append(MFNode(level+1,n,a,b,d,count,sum)); return MFT_NODE_BASE+id
fn mf_single(mut c: MFContext,level: Int,item: Int) -> Int:
    if c.trees.size()+c.nodes.size()>=MFT_ARENA or c.trees.size()>=MFT_NODE_BASE: c.failed=True; return 0
    let m=mf_measure_ref(c,item); let id=c.trees.size()
    c.trees.append(MFTree(1,level,1,0,-1,item,0,0,0,0,0,0,0,m.count,m.sum)); return id
fn mf_deep(mut c: MFContext,level: Int,pre: InlineArray[Int,4],pn: Int,mid: Int,suf: InlineArray[Int,4],sn: Int) -> Int:
    if pn<=0 or sn<=0: c.failed=True; return mf_empty(mut c,level)
    if c.trees.size()+c.nodes.size()>=MFT_ARENA or c.trees.size()>=MFT_NODE_BASE: c.failed=True; return 0
    var m=mf_measure_tree(c,mid)
    for i in range(pn): m=mf_add(m,mf_measure_ref(c,pre[i]))
    for i in range(sn): m=mf_add(m,mf_measure_ref(c,suf[i]))
    let id=c.trees.size()
    c.trees.append(MFTree(2,level,pn,sn,mid,pre[0],pre[1],pre[2],pre[3],suf[0],suf[1],suf[2],suf[3],m.count,m.sum)); return id

fn mf_cons(mut c: MFContext,level: Int,item: Int,id: Int) -> Int:
    let t=mf_tree(c,id)
    if t.kind==0: return mf_single(mut c,level,item)
    if t.kind==1:
        var p=InlineArray[Int,4](); var s=InlineArray[Int,4](); p[0]=item; s[0]=t.p0
        let middle=mf_empty(mut c,level+1)
        return mf_deep(mut c,level,p,1,middle,s,1)
    if t.plen<4:
        var p=InlineArray[Int,4](); p[0]=item
        for i in range(t.plen): p[i+1]=mt_pre(t,i)
        var s=InlineArray[Int,4](); for i in range(t.slen): s[i]=mt_suf(t,i)
        return mf_deep(mut c,level,p,t.plen+1,t.mid,s,t.slen)
    var g=InlineArray[Int,4]();g[0]=t.p1;g[1]=t.p2;g[2]=t.p3
    let grouped=mf_node(mut c,level,g,3)
    let middle=mf_cons(mut c,level+1,grouped,t.mid)
    var p=InlineArray[Int,4]();p[0]=item;p[1]=t.p0;var s=InlineArray[Int,4]();for i in range(t.slen):s[i]=mt_suf(t,i)
    return mf_deep(mut c,level,p,2,middle,s,t.slen)
fn mf_snoc(mut c: MFContext,level: Int,id: Int,item: Int) -> Int:
    let t=mf_tree(c,id)
    if t.kind==0:return mf_single(mut c,level,item)
    if t.kind==1:
        var p=InlineArray[Int,4]();var s=InlineArray[Int,4]();p[0]=t.p0;s[0]=item
        let middle=mf_empty(mut c,level+1)
        return mf_deep(mut c,level,p,1,middle,s,1)
    if t.slen<4:
        var p=InlineArray[Int,4]();var s=InlineArray[Int,4]();for i in range(t.plen):p[i]=mt_pre(t,i)
        for i in range(t.slen):
            s[i]=mt_suf(t,i)
        s[t.slen]=item
        return mf_deep(mut c,level,p,t.plen,t.mid,s,t.slen+1)
    var g=InlineArray[Int,4]();g[0]=t.s0;g[1]=t.s1;g[2]=t.s2
    let grouped=mf_node(mut c,level,g,3)
    let middle=mf_snoc(mut c,level+1,t.mid,grouped)
    var p=InlineArray[Int,4]();for i in range(t.plen):p[i]=mt_pre(t,i)
    var s=InlineArray[Int,4]();s[0]=t.s3;s[1]=item
    return mf_deep(mut c,level,p,t.plen,middle,s,2)

fn mf_from(mut c: MFContext,level: Int,items: InlineArray[Int,16],n: Int) -> Int:
    var out=mf_empty(mut c,level)
    for i in range(n):out=mf_snoc(mut c,level,out,items[i])
    return out
fn mf_view_left(mut c: MFContext,level: Int,id: Int) -> MFView:
    let t=mf_tree(c,id)
    if t.kind==0:return MFView(False,0,id)
    if t.kind==1:return MFView(True,t.p0,mf_empty(mut c,level))
    let item=t.p0;var rest=0
    if t.plen>1:
        var p=InlineArray[Int,4]();var s=InlineArray[Int,4]();for i in range(1,t.plen):p[i-1]=mt_pre(t,i)
        for i in range(t.slen):s[i]=mt_suf(t,i)
        rest=mf_deep(mut c,level,p,t.plen-1,t.mid,s,t.slen)
    else:
        let mv=mf_view_left(mut c,level+1,t.mid)
        if not mv.found:
            var x=InlineArray[Int,16]()
            for i in range(t.slen): x[i]=mt_suf(t,i)
            rest=mf_from(mut c,level,x,t.slen)
        else:
            let nd=c.nodes[mv.item-MFT_NODE_BASE];var p=InlineArray[Int,4]();var s=InlineArray[Int,4]();for i in range(nd.arity):p[i]=mf_node_child(nd,i)
            for i in range(t.slen): s[i]=mt_suf(t,i)
            rest=mf_deep(mut c,level,p,nd.arity,mv.tree,s,t.slen)
    return MFView(True,item,rest)
fn mf_view_right(mut c: MFContext,level: Int,id: Int) -> MFView:
    let t=mf_tree(c,id)
    if t.kind==0:return MFView(False,0,id)
    if t.kind==1:return MFView(True,t.p0,mf_empty(mut c,level))
    let item=mt_suf(t,t.slen-1);var rest=0
    if t.slen>1:
        var p=InlineArray[Int,4]();var s=InlineArray[Int,4]();for i in range(t.plen):p[i]=mt_pre(t,i)
        for i in range(t.slen-1): s[i]=mt_suf(t,i)
        rest=mf_deep(mut c,level,p,t.plen,t.mid,s,t.slen-1)
    else:
        let mv=mf_view_right(mut c,level+1,t.mid)
        if not mv.found:
            var x=InlineArray[Int,16]()
            for i in range(t.plen): x[i]=mt_pre(t,i)
            rest=mf_from(mut c,level,x,t.plen)
        else:
            let nd=c.nodes[mv.item-MFT_NODE_BASE];var p=InlineArray[Int,4]();var s=InlineArray[Int,4]();for i in range(t.plen):p[i]=mt_pre(t,i)
            for i in range(nd.arity): s[i]=mf_node_child(nd,i)
            rest=mf_deep(mut c,level,p,t.plen,mv.tree,s,nd.arity)
    return MFView(True,item,rest)

fn mf_deep_left(mut c: MFContext,level: Int,pre: InlineArray[Int,4],pn: Int,
                mid: Int,suf: InlineArray[Int,4],sn: Int) -> Int:
    if pn>0: return mf_deep(mut c,level,pre,pn,mid,suf,sn)
    let v=mf_view_left(mut c,level+1,mid)
    if not v.found:
        var items=InlineArray[Int,16]()
        for i in range(sn): items[i]=suf[i]
        return mf_from(mut c,level,items,sn)
    let node=c.nodes[v.item-MFT_NODE_BASE]
    var promoted=InlineArray[Int,4]()
    for i in range(Int(node.arity)): promoted[i]=mf_node_child(node,i)
    return mf_deep(mut c,level,promoted,Int(node.arity),v.tree,suf,sn)

fn mf_deep_right(mut c: MFContext,level: Int,pre: InlineArray[Int,4],pn: Int,
                 mid: Int,suf: InlineArray[Int,4],sn: Int) -> Int:
    if sn>0: return mf_deep(mut c,level,pre,pn,mid,suf,sn)
    let v=mf_view_right(mut c,level+1,mid)
    if not v.found:
        var items=InlineArray[Int,16]()
        for i in range(pn): items[i]=pre[i]
        return mf_from(mut c,level,items,pn)
    let node=c.nodes[v.item-MFT_NODE_BASE]
    var promoted=InlineArray[Int,4]()
    for i in range(Int(node.arity)): promoted[i]=mf_node_child(node,i)
    return mf_deep(mut c,level,pre,pn,v.tree,promoted,Int(node.arity))

fn mf_group(mut c: MFContext,level: Int,items: InlineArray[Int,16],n: Int) -> InlineArray[Int,8]:
    var out=InlineArray[Int,8]();var used=0;var pos=0
    while pos<n:
        let rem=n-pos;let take=2 if rem==2 or rem==4 else 3
        if rem==1:c.failed=True;return out
        var g=InlineArray[Int,4]();for i in range(take):g[i]=items[pos+i]
        out[used]=mf_node(mut c,level,g,take);used+=1;pos+=take
    out[7]=used
    return out
fn mf_append(mut c: MFContext,level: Int,left: Int,bridge: InlineArray[Int,16],bn: Int,right: Int) -> Int:
    let a=mf_tree(c,left);let b=mf_tree(c,right)
    if a.kind==0:
        var out=right
        for i in range(bn-1,-1,-1): out=mf_cons(mut c,level,bridge[i],out)
        return out
    if b.kind==0:
        var out=left
        for i in range(bn): out=mf_snoc(mut c,level,out,bridge[i])
        return out
    if a.kind==1:
        var out=right
        for i in range(bn-1,-1,-1): out=mf_cons(mut c,level,bridge[i],out)
        return mf_cons(mut c,level,a.p0,out)
    if b.kind==1:
        var out=left
        for i in range(bn): out=mf_snoc(mut c,level,out,bridge[i])
        return mf_snoc(mut c,level,out,b.p0)
    var all=InlineArray[Int,16]();var n=0
    for i in range(a.slen):
        all[n]=mt_suf(a,i);n+=1
    for i in range(bn):
        all[n]=bridge[i];n+=1
    for i in range(b.plen):
        all[n]=mt_pre(b,i);n+=1
    let groups=mf_group(mut c,level,all,n);let nn=groups[7];var nodes=InlineArray[Int,16]();for i in range(nn):nodes[i]=groups[i]
    let middle=mf_append(mut c,level+1,a.mid,nodes,nn,b.mid)
    var p=InlineArray[Int,4]();var s=InlineArray[Int,4]()
    for i in range(a.plen): p[i]=mt_pre(a,i)
    for i in range(b.slen): s[i]=mt_suf(b,i)
    return mf_deep(mut c,level,p,a.plen,middle,s,b.slen)

fn mf_pred(mode: Int,target: Int64,m: MFMeasure) -> Bool:return m.count>Int(target) if mode==0 else m.sum>=target
fn mf_split(mut c: MFContext,id: Int,acc: MFMeasure,mode: Int,target: Int64) -> MFSplit:
    let t=mf_tree(c,id)
    if t.kind==0:return MFSplit(False,0,id,mf_empty(mut c,t.level))
    if t.kind==1:
        if mf_pred(mode,target,mf_add(acc,mf_measure_ref(c,t.p0))):
            let e=mf_empty(mut c,t.level)
            return MFSplit(True,t.p0,e,e)
        return MFSplit(False,0,id,mf_empty(mut c,t.level))
    var cur=acc;var pre=InlineArray[Int,4]();var pn=0
    for i in range(t.plen):
        let item=mt_pre(t,i);cur=mf_add(cur,mf_measure_ref(c,item));pre[pn]=item;pn+=1
        if mf_pred(mode,target,cur):
            var litems=InlineArray[Int,16]();for j in range(pn-1):litems[j]=pre[j]
            let l=mf_from(mut c,t.level,litems,pn-1)
            var rest=InlineArray[Int,4]()
            for j in range(pn,t.plen): rest[j-pn]=mt_pre(t,j)
            var suf=InlineArray[Int,4]()
            for j in range(t.slen): suf[j]=mt_suf(t,j)
            let r=mf_deep_left(mut c,t.level,rest,t.plen-pn,t.mid,suf,t.slen);return MFSplit(True,item,l,r)
    var prefix=acc;for i in range(t.plen):prefix=mf_add(prefix,mf_measure_ref(c,mt_pre(t,i)))
    let mid=mf_add(prefix,mf_measure_tree(c,t.mid))
    if mf_pred(mode,target,mid):
        let sm=mf_split(mut c,t.mid,prefix,mode,target);if not sm.found:c.failed=True;return MFSplit(False,0,id,mf_empty(mut c,t.level))
        let nd=c.nodes[sm.item-MFT_NODE_BASE];var ca=mf_add(prefix,mf_measure_tree(c,sm.left));var before=InlineArray[Int,4]();var after=InlineArray[Int,4]();var nb=0;var na=0;var pivot=0;var found=False
        for i in range(nd.arity):
            let item=mf_node_child(nd,i);let next=mf_add(ca,mf_measure_ref(c,item))
            if not found and mf_pred(mode,target,next):pivot=item;found=True
            elif not found:before[nb]=item;nb+=1;ca=next
            else:after[na]=item;na+=1
        if not found:c.failed=True;return MFSplit(False,0,id,mf_empty(mut c,t.level))
        var p=InlineArray[Int,4]();var s=InlineArray[Int,4]()
        for i in range(t.plen): p[i]=mt_pre(t,i)
        for i in range(nb): s[i]=before[i]
        let l=mf_deep_right(mut c,t.level,p,t.plen,sm.left,s,nb)
        var rp=InlineArray[Int,4]()
        for i in range(na): rp[i]=after[i]
        for i in range(t.slen): s[i]=mt_suf(t,i)
        let r=mf_deep_left(mut c,t.level,rp,na,sm.right,s,t.slen);return MFSplit(True,pivot,l,r)
    cur=mid;var sufpart=InlineArray[Int,4]();var sn=0
    for i in range(t.slen):
        let item=mt_suf(t,i);cur=mf_add(cur,mf_measure_ref(c,item));sufpart[sn]=item;sn+=1
        if mf_pred(mode,target,cur):
            var p=InlineArray[Int,4]()
            for j in range(t.plen): p[j]=mt_pre(t,j)
            let l=mf_deep_right(mut c,t.level,p,t.plen,t.mid,sufpart,sn-1)
            var ri=InlineArray[Int,16]()
            for j in range(sn,t.slen): ri[j-sn]=mt_suf(t,j)
            let r=mf_from(mut c,t.level,ri,t.slen-sn)
            return MFSplit(True,item,l,r)
    return MFSplit(False,0,id,mf_empty(mut c,t.level))

fn mf_put64(out: UnsafePointer[UInt8,MutAnyOrigin],offset: Int,value: Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[offset+b]=UInt8((bits>>(b*8))&255)

@export("measured_finger_tree_sequence")
fn measured_finger_tree_sequence(input: UnsafePointer[Int64,ImmutAnyOrigin],length: c_size_t,
    output: UnsafePointer[UInt8,MutAnyOrigin],capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or Int(length)<2 or Int(length)>MFT_MAX_PARSEABLE:return -1
    let n64=input[0];if n64<0 or n64>32:return -1
    let n=Int(n64);if Int(length)<n+2:return -1
    let q64=input[n+1];if q64<1 or q64>32:return -1
    let q=Int(q64);if Int(length)!=n+2+5*q or Int(length)>MFT_MAX_INPUT:return -1
    var c=MFContext();var roots=InlineArray[MFRoot,MFT_ROOTS]();var nr=1;var tree=mf_empty(mut c,0)
    for i in range(n):
        let value=input[1+i];if value<0 or value>1000000:return -1
        tree=mf_snoc(mut c,0,tree,Int(-value-1))
    if c.failed:return -1
    let initial=mf_measure_tree(c,tree);if initial.count>64 or initial.sum>MFT_MAX_SUM:return -1
    roots[0]=MFRoot(tree,initial.count,initial.sum);var records=InlineArray[Int64,MFT_Q*7]();var cursor=n+2
    for op in range(q):
        let tag64=input[cursor];let a64=input[cursor+1];let b64=input[cursor+2];let x=input[cursor+3];let y=input[cursor+4];cursor+=5
        if tag64<0 or tag64>6 or a64<0 or a64>=nr or nr>=MFT_ROOTS:return -1
        let tag=Int(tag64);let a=Int(a64);let first=roots[a].tree;var second=-1;var result=0;var result2=0;var aux=Int64(-1);var two=False
        if tag==0 or tag==1:
            if b64 != -1 or y != -1 or x<0 or x>1000000 or roots[a].length>=64 or roots[a].sum+x>MFT_MAX_SUM:return -1
            let item=Int(-x-1);result=mf_cons(mut c,0,item,first) if tag==0 else mf_snoc(mut c,0,first,item)
        elif tag==2 or tag==3:
            if b64 != -1 or x != -1 or y != -1 or roots[a].length==0:return -1
            let v=mf_view_left(mut c,0,first) if tag==2 else mf_view_right(mut c,0,first)
            if not v.found:return -1
            result=v.tree;aux=Int64(-v.item-1)
        elif tag==4:
            if b64<0 or b64>=nr or x != -1 or y != -1:return -1
            let b=Int(b64);if roots[a].length+roots[b].length>64 or roots[a].sum+roots[b].sum>MFT_MAX_SUM:return -1
            result=mf_append(mut c,0,first,InlineArray[Int,16](),0,roots[b].tree)
        else:
            if b64 != -1 or y != -1:return -1
            let mode=0 if tag==5 else 1
            if (tag==5 and (x<0 or x>roots[a].length)) or (tag==6 and (x<1 or x>MFT_MAX_SUM)):return -1
            let s=mf_split(mut c,first,MFMeasure(0,0),mode,x)
            if s.found:
                if tag==5:
                    result=s.left
                    result2=mf_cons(mut c,0,s.item,s.right)
                    aux=x
                else:
                    result=mf_snoc(mut c,0,s.left,s.item)
                    result2=s.right
                    aux=Int64(mf_measure_tree(c,result).count)
            else:result=first;result2=mf_empty(mut c,0);aux=x if tag==5 else Int64(-1)
            two=True
        if c.failed:return -1
        let m1=mf_measure_tree(c,result);if m1.count>64 or m1.sum>MFT_MAX_SUM:return -1
        let left_id=nr;roots[nr]=MFRoot(result,m1.count,m1.sum);nr+=1;var right_len=Int64(-1);var right_sum=Int64(-1)
        if two:
            let m2=mf_measure_tree(c,result2);if m2.count>64 or m2.sum>MFT_MAX_SUM or nr>=MFT_ROOTS:return -1
            second=nr;roots[nr]=MFRoot(result2,m2.count,m2.sum);nr+=1;right_len=Int64(m2.count);right_sum=m2.sum
        let z=7*op;records[z]=Int64(left_id);records[z+1]=Int64(m1.count);records[z+2]=m1.sum;records[z+3]=Int64(second);records[z+4]=right_len;records[z+5]=right_sum;records[z+6]=aux
    let bytes=56*q
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or Int(capacity)<bytes:return -2
    for i in range(7*q):mf_put64(output,8*i,records[i])
    return Int64(bytes)

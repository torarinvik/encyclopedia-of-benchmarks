// Bounded ParGeo-style logarithmic batch-dynamic point forest; see package README/LICENSE.
package batch_dynamic_kd_tree
import "core:c"
 Bdk_Node :: struct { id, left, right: int; minx, maxx, miny, maxy: i64 }
bdk_less :: proc(a,b,axis:int,x,y:^([32]i64))->bool{av:=x[a];bv:=x[b];aw:=y[a];bw:=y[b];if axis==1{av,bv=aw,bw;aw,bw=x[a],x[b]};if av!=bv{return av<bv};return aw!=bw?aw<bw:a<b}
bdk_box :: proc(n:^Bdk_Node,qx,qy:i64)->i64{dx:=i64(0);dy:=i64(0);if qx<n.minx{dx=n.minx-qx}else if qx>n.maxx{dx=qx-n.maxx};if qy<n.miny{dy=n.miny-qy}else if qy>n.maxy{dy=qy-n.maxy};return dx*dx+dy*dy}
bdk_build :: proc(ids:^([32]int),lo,hi,depth:int,x,y:^([32]i64),nodes:^([32]Bdk_Node),used:^int)->int{if lo>=hi{return -1};axis:=depth%2;for i:=lo+1;i<hi;i+=1{v:=ids[i];j:=i;for j>lo&&bdk_less(v,ids[j-1],axis,x,y){ids[j]=ids[j-1];j-=1};ids[j]=v};mid:=lo+(hi-lo)/2;at:=used.*;used.*+=1;id:=ids[mid];nodes[at].id=id;left:=bdk_build(ids,lo,mid,depth+1,x,y,nodes,used);right:=bdk_build(ids,mid+1,hi,depth+1,x,y,nodes,used);nodes[at].left=left;nodes[at].right=right;nodes[at].minx=x[id];nodes[at].maxx=x[id];nodes[at].miny=y[id];nodes[at].maxy=y[id];for child in [2]int{left,right}{if child>=0{nodes[at].minx=min(nodes[at].minx,nodes[child].minx);nodes[at].maxx=max(nodes[at].maxx,nodes[child].maxx);nodes[at].miny=min(nodes[at].miny,nodes[child].miny);nodes[at].maxy=max(nodes[at].maxy,nodes[child].maxy)}};return at}
bdk_query :: proc(at:int,nodes:^([32]Bdk_Node),x,y:^([32]i64),active:^([32]bool),qx,qy:i64,found:^bool,best_id:^int,best:^i64){if at<0{return};n:=nodes[at];if found.*&&bdk_box(&n,qx,qy)>best.*{return};id:=n.id;if active[id]{dx:=x[id]-qx;dy:=y[id]-qy;d:=dx*dx+dy*dy;if !found.*||d<best.*||(d==best.*&&id<best_id.*){found.*=true;best.*=d;best_id.*=id}};a:=n.left;b:=n.right;if a>=0&&b>=0&&bdk_box(&nodes[b],qx,qy)<bdk_box(&nodes[a],qx,qy){a,b=b,a};bdk_query(a,nodes,x,y,active,qx,qy,found,best_id,best);bdk_query(b,nodes,x,y,active,qx,qy,found,best_id,best)}
@(export)
batch_dynamic_kd_tree :: proc "c" (input: [^]i64, input_length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input==nil || input_length<2 || input_length>250 do return -1
    initial:=input[0];if initial<0 || initial>8 || input_length<c.size_t(2+3*initial) do return -1
    x,y,answers: [32]i64;active,ever: [32]bool;levels: [6][32]int;sizes: [6]int;pos:=c.size_t(1);inserted:=0
    for i:=0;i<int(initial);i+=1 { id,px,py:=input[pos],input[pos+1],input[pos+2];pos+=3;if id<0 || id>=32 || ever[id] || px< -1000 || px>1000 || py< -1000 || py>1000 do return -1;for j:=0;j<32;j+=1 { if active[j] && x[j]==px && y[j]==py do return -1 };x[id]=px;y[id]=py;ever[id]=true;active[id]=true;inserted+=1
        carry: [32]int;carry[0]=int(id);carry_count:=1
        for level:=0;level<6;level+=1 { if sizes[level]==0 { for j:=0;j<carry_count;j+=1 { levels[level][j]=carry[j] };sizes[level]=carry_count;break };next: [32]int;next_count:=0;for j:=0;j<sizes[level];j+=1 { next[next_count]=levels[level][j];next_count+=1 };for j:=0;j<carry_count;j+=1 { next[next_count]=carry[j];next_count+=1 };sizes[level]=0;for j:=0;j<next_count;j+=1 { carry[j]=next[j] };carry_count=next_count }
    }
    if pos>=input_length do return -1
    batch_value:=input[pos];pos+=1;if batch_value<1 || batch_value>8 do return -1;batches:=int(batch_value)
    for batch:=0;batch<batches;batch+=1 {
        if pos+2>input_length do return -1
        kind,count_value:=input[pos],input[pos+1];pos+=2;if (kind!=0 && kind!=1) || count_value<1 || count_value>8 do return -1;count:=int(count_value)
        if kind==0 {
            if inserted+count>32 || pos+3*c.size_t(count)+2>input_length do return -1
            records_start:=pos
            for j:=0;j<count;j+=1 { id,px,py:=input[pos],input[pos+1],input[pos+2];pos+=3;if id<0 || id>=32 || ever[id] || px< -1000 || px>1000 || py< -1000 || py>1000 do return -1;for t:=0;t<32;t+=1 { if active[t] && x[t]==px && y[t]==py do return -1 };for t:=0;t<j;t+=1 { if input[records_start+3*c.size_t(t)+1]==px && input[records_start+3*c.size_t(t)+2]==py do return -1 };x[id]=px;y[id]=py;ever[id]=true;active[id]=true;inserted+=1
                carry: [32]int;carry[0]=int(id);carry_count:=1
                for level:=0;level<6;level+=1 { if sizes[level]==0 { for z:=0;z<carry_count;z+=1 { levels[level][z]=carry[z] };sizes[level]=carry_count;break };next: [32]int;next_count:=0;for z:=0;z<sizes[level];z+=1 { next[next_count]=levels[level][z];next_count+=1 };for z:=0;z<carry_count;z+=1 { next[next_count]=carry[z];next_count+=1 };sizes[level]=0;for z:=0;z<next_count;z+=1 { carry[z]=next[z] };carry_count=next_count }
            }
        } else {
            if pos+c.size_t(count)+2>input_length do return -1
            for j:=0;j<count;j+=1 { id:=input[pos];pos+=1;if id<0 || id>=32 || !active[id] do return -1;active[id]=false }
        }
        if pos+2>input_length do return -1
        qx,qy:=input[pos],input[pos+1];pos+=2;if qx< -1000 || qx>1000 || qy< -1000 || qy>1000 do return -1;found:=false;best:=i64(0);best_id:=0
        for level:=0;level<6;level+=1 { if sizes[level]>0 { ids: [32]int;for j:=0;j<sizes[level];j+=1 { ids[j]=levels[level][j] };nodes: [32]Bdk_Node;used:=0;root:=bdk_build(&ids,0,sizes[level],0,&x,&y,&nodes,&used);bdk_query(root,&nodes,&x,&y,&active,qx,qy,&found,&best_id,&best) } };if !found do return -1;answers[batch]=best
    }
    if pos!=input_length do return -1
    needed:=c.size_t(8*batches);if output==nil || output_capacity<needed do return -2
    for i:=c.size_t(0);i<needed;i+=1 { output[i]=u8(u64(answers[i/8])>>(8*(i%8))) }
    return i64(needed)
}

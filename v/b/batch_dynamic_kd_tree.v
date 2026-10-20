// Bounded ParGeo-style logarithmic batch-dynamic point forest; see package README/LICENSE.
module batch_dynamic_kd_tree

struct BdkNode { id int; left int; right int; minx i64; maxx i64; miny i64; maxy i64 }
fn bdk_less(a int,b int,axis int,x []i64,y []i64) bool { mut av,bv,aw,bw:=x[a],x[b],y[a],y[b];if axis==1{av,bv,aw,bw=y[a],y[b],x[a],x[b]};return if av!=bv{av<bv}else if aw!=bw{aw<bw}else{a<b} }
fn bdk_build(mut ids []int,lo int,hi int,depth int,x []i64,y []i64,mut nodes []BdkNode,mut used int) int {if lo>=hi{return -1};axis:=depth%2;for i:=lo+1;i<hi;i++{value:=ids[i];mut j:=i;for j>lo&&bdk_less(value,ids[j-1],axis,x,y){ids[j]=ids[j-1];j--};ids[j]=value};middle:=lo+(hi-lo)/2;at:=used;used++;id:=ids[middle];left:=bdk_build(mut ids,lo,middle,depth+1,x,y,mut nodes,mut used);right:=bdk_build(mut ids,middle+1,hi,depth+1,x,y,mut nodes,mut used);nodes[at]=BdkNode{id:id,left:left,right:right,minx:x[id],maxx:x[id],miny:y[id],maxy:y[id]};for child in [left,right]{if child>=0{nodes[at].minx=min(nodes[at].minx,nodes[child].minx);nodes[at].maxx=max(nodes[at].maxx,nodes[child].maxx);nodes[at].miny=min(nodes[at].miny,nodes[child].miny);nodes[at].maxy=max(nodes[at].maxy,nodes[child].maxy)}};return at}
fn bdk_box(n BdkNode,qx i64,qy i64) i64 {dx:=if qx<n.minx{n.minx-qx}else if qx>n.maxx{qx-n.maxx}else{i64(0)};dy:=if qy<n.miny{n.miny-qy}else if qy>n.maxy{qy-n.maxy}else{i64(0)};return dx*dx+dy*dy}
fn bdk_query(at int,nodes []BdkNode,x []i64,y []i64,active []bool,qx i64,qy i64,mut found bool,mut best_id int,mut best i64) {if at<0{return};n:=nodes[at];if found&&bdk_box(n,qx,qy)>best{return};id:=n.id;if active[id]{dx,dy:=x[id]-qx,y[id]-qy;d:=dx*dx+dy*dy;if !found||d<best||(d==best&&id<best_id){found=true;best=d;best_id=id}};mut a,b:=n.left,n.right;if a>=0&&b>=0&&bdk_box(nodes[b],qx,qy)<bdk_box(nodes[a],qx,qy){a,b=b,a};bdk_query(a,nodes,x,y,active,qx,qy,mut found,mut best_id,mut best);bdk_query(b,nodes,x,y,active,qx,qy,mut found,mut best_id,mut best)}

@[export: 'batch_dynamic_kd_tree']
pub fn batch_dynamic_kd_tree(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input==nil || input_length<2 || input_length>250 { return -1 }
		initial:=input[0]
		if initial<0 || initial>8 || input_length<usize(2+3*initial) { return -1 }
		mut x:=[32]i64{}
		mut y:=[32]i64{}
		mut answers:=[8]i64{}
		mut active:=[32]bool{}
		mut ever:=[32]bool{}
		mut levels:=[6][32]int{}
		mut sizes:=[6]int{}
		mut pos:=1
		mut inserted:=0
		for _ in 0 .. int(initial) {
			id:=input[pos];px:=input[pos+1];py:=input[pos+2];pos+=3
			if id<0 || id>=32 || ever[id] || px< -1000 || px>1000 || py< -1000 || py>1000 { return -1 }
			for j in 0 .. 32 { if active[j] && x[j]==px && y[j]==py { return -1 } }
			x[id]=px;y[id]=py;ever[id]=true;active[id]=true;inserted++
			mut carry:=[32]int{};carry[0]=int(id);mut carry_count:=1
			for level in 0 .. 6 {
				if sizes[level]==0 { for j in 0 .. carry_count { levels[level][j]=carry[j] };sizes[level]=carry_count;break }
				mut next:=[32]int{};mut next_count:=0
				for j in 0 .. sizes[level] { next[next_count]=levels[level][j];next_count++ }
				for j in 0 .. carry_count { next[next_count]=carry[j];next_count++ }
				sizes[level]=0;for j in 0 .. next_count { carry[j]=next[j] };carry_count=next_count
			}
		}
		if pos>=int(input_length) { return -1 }
		batch_value:=input[pos];pos++;if batch_value<1 || batch_value>8 { return -1 };batches:=int(batch_value)
		for batch in 0 .. batches {
			if pos+2>int(input_length) { return -1 }
			kind:=input[pos];count_value:=input[pos+1];pos+=2
			if (kind!=0 && kind!=1) || count_value<1 || count_value>8 { return -1 };count:=int(count_value)
			if kind==0 {
				if inserted+count>32 || pos+3*count+2>int(input_length) { return -1 };records_start:=pos
				for j in 0 .. count {
					id:=input[pos];px:=input[pos+1];py:=input[pos+2];pos+=3
					if id<0 || id>=32 || ever[id] || px< -1000 || px>1000 || py< -1000 || py>1000 { return -1 }
					for t in 0 .. 32 { if active[t] && x[t]==px && y[t]==py { return -1 } }
					for t in 0 .. j { if input[records_start+3*t+1]==px && input[records_start+3*t+2]==py { return -1 } }
					x[id]=px;y[id]=py;ever[id]=true;active[id]=true;inserted++
					mut carry:=[32]int{};carry[0]=int(id);mut carry_count:=1
					for level in 0 .. 6 { if sizes[level]==0 { for z in 0 .. carry_count { levels[level][z]=carry[z] };sizes[level]=carry_count;break };mut next:=[32]int{};mut next_count:=0;for z in 0 .. sizes[level] { next[next_count]=levels[level][z];next_count++ };for z in 0 .. carry_count { next[next_count]=carry[z];next_count++ };sizes[level]=0;for z in 0 .. next_count { carry[z]=next[z] };carry_count=next_count }
				}
			} else {
				if pos+count+2>int(input_length) { return -1 }
				for _ in 0 .. count { id:=input[pos];pos++;if id<0 || id>=32 || !active[id] { return -1 };active[id]=false }
			}
			if pos+2>int(input_length) { return -1 };qx:=input[pos];qy:=input[pos+1];pos+=2
			if qx< -1000 || qx>1000 || qy< -1000 || qy>1000 { return -1 }
			mut found:=false;mut best:=i64(0);mut best_id:=0
			for level in 0 .. 6 { if sizes[level]>0 { mut ids:=[]int{len:sizes[level]};for j in 0 .. sizes[level] { ids[j]=levels[level][j] };mut nodes:=[]BdkNode{len:32};mut used:=0;root:=bdk_build(mut ids,0,sizes[level],0,x[..],y[..],mut nodes,mut used);bdk_query(root,nodes,x[..],y[..],active[..],qx,qy,mut found,mut best_id,mut best) } }
			if !found { return -1 };answers[batch]=best
		}
		if pos!=int(input_length) { return -1 };needed:=8*batches
		if output==nil || output_capacity<usize(needed) { return -2 }
		for i in 0 .. needed { output[i]=u8(u64(answers[i/8])>>(8*(i%8))) }
		return i64(needed)
	}
}

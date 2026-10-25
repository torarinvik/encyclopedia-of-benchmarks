module versabench_dbms_insert_entry

const max_depth = 2
const max_children = 4
const max_leaf = 3
const max_words = 28

fn valid_box(b [8]i64) bool {
	for d in 0 .. 4 { if b[d] < -8 || b[d] > 8 || b[4+d] < -8 || b[4+d] > 8 || b[d] >= b[4+d] { return false } }
	return true
}
fn union_boxes(boxes [][8]i64) [8]i64 {
	mut out := boxes[0]
	for i in 1 .. boxes.len { for d in 0 .. 4 { out[d] = min(out[d],boxes[i][d]); out[4+d] = max(out[4+d],boxes[i][4+d]) } }
	return out
}
fn volume(b [8]i64) i64 { mut result := i64(1); for d in 0 .. 4 { result *= b[4+d]-b[d] }; return result }
fn same_box(a [8]i64,b [8]i64) bool { for i in 0 .. 8 { if a[i] != b[i] { return false } }; return true }
fn write_i64(output &u8,word int,value i64) { bits:=u64(value); for b in 0 .. 8 { unsafe { output[word*8+b]=u8((bits >> u64(8*b)) & 255) } } }

@[export: 'versabench_dbms_insert_entry']
pub fn versabench_dbms_insert_entry(input &i64,length usize,output &u8,output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 11 || length > 105 { return -1 }
		depthv:=input[0]; new_id:=input[1]
		if depthv < 0 || depthv > max_depth || new_id < 0 || new_id >= 32 { return -1 }
		depth:=int(depthv); mut incoming:=[8]i64{}
		for i in 0 .. 8 { incoming[i]=input[2+i] }; if !valid_box(incoming) { return -1 }
		mut branches:=[max_depth][max_children][8]i64{}; mut counts:=[max_depth]int{}; mut pos:=10
		for level in 0 .. depth {
			if pos >= int(length) { return -1 }; cv:=input[pos]; pos++
			if cv < 1 || cv > max_children || pos+int(cv)*8 > int(length) { return -1 }
			counts[level]=int(cv)
			for i in 0 .. counts[level] { mut b:=[8]i64{}; for j in 0 .. 8 { b[j]=input[pos+j] }; pos+=8; if !valid_box(b) { return -1 }; branches[level][i]=b }
		}
		if pos >= int(length) { return -1 }; lv:=input[pos]; pos++
		if lv < 0 || lv > max_leaf || (depth > 0 && lv == 0) || pos+int(lv)*9 > int(length) { return -1 }
		leaf_count:=int(lv); mut leaves:=[max_leaf][8]i64{}; mut ids:=[max_leaf]i64{}; mut seen:=[32]bool{}
		for i in 0 .. leaf_count { for j in 0 .. 8 { leaves[i][j]=input[pos+j] }; pos+=8; ids[i]=input[pos]; pos++; if !valid_box(leaves[i]) || ids[i] < 0 || ids[i] >= 32 || seen[int(ids[i])] { return -1 }; seen[int(ids[i])]=true }
		if pos != int(length) || seen[int(new_id)] { return -1 }
		mut choices:=[max_depth]int{}
		for level in 0 .. depth { mut best:=i64(65536); for i in 0 .. counts[level] { mut joined:=[8]i64{}; for d in 0 .. 4 { joined[d]=min(branches[level][i][d],incoming[d]); joined[4+d]=max(branches[level][i][4+d],incoming[4+d]) }; penalty:=volume(joined)-volume(branches[level][i]); if penalty < best { best=penalty; choices[level]=i } } }
		if depth > 0 { pre:=union_boxes(leaves[..leaf_count]); for rev in 0 .. depth { level:=depth-1-rev; if !same_box(branches[level][choices[level]],pre) { return -1 }; pre=union_boxes(branches[level][..counts[level]]) } }
		mut staged:=[max_leaf+1][8]i64{}; for i in 0 .. leaf_count { staged[i]=leaves[i] }; staged[leaf_count]=incoming
		mut child:=union_boxes(staged[..leaf_count+1]); mut result:=[max_words]i64{}; mut outn:=0
		result[outn]=depth; outn++; result[outn]=new_id; outn++; for i in 0 .. depth { result[outn]=choices[i]; outn++ }; for d in 0 .. 8 { result[outn]=child[d]; outn++ }
		for rev in 0 .. depth { level:=depth-1-rev; branches[level][choices[level]]=child; child=union_boxes(branches[level][..counts[level]]); for d in 0 .. 8 { result[outn]=child[d]; outn++ } }
		bytes:=outn*8; if output == nil || output_capacity < usize(bytes) { return -2 }; for i in 0 .. outn { write_i64(output,i,result[i]) }; return i64(bytes)
	}
}

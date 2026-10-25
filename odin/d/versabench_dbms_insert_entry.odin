package versabench_dbms_insert_entry
import "core:c"

MAX_DEPTH :: 2
MAX_CHILDREN :: 4
MAX_LEAF :: 3
MAX_WORDS :: 28
valid_box :: proc "contextless" (b: [8]i64) -> bool { for d := 0; d < 4; d += 1 { if b[d] < -8 || b[d] > 8 || b[4+d] < -8 || b[4+d] > 8 || b[d] >= b[4+d] do return false }; return true }
union_boxes :: proc "contextless" (boxes: [][8]i64) -> (out: [8]i64) { out=boxes[0]; for i := 1; i < len(boxes); i += 1 { for d := 0; d < 4; d += 1 { if boxes[i][d] < out[d] do out[d]=boxes[i][d]; if boxes[i][4+d] > out[4+d] do out[4+d]=boxes[i][4+d] } }; return }
volume :: proc "contextless" (b: [8]i64) -> i64 { result:=i64(1); for d := 0; d < 4; d += 1 { result *= b[4+d]-b[d] }; return result }
same_box :: proc "contextless" (a,b: [8]i64) -> bool { for i := 0; i < 8; i += 1 { if a[i] != b[i] do return false }; return true }
write_i64 :: proc "contextless" (output: [^]u8,word: int,value: i64) { bits:=u64(value); for b := 0; b < 8; b += 1 { output[word*8+b]=u8((bits >> u64(8*b)) & 255) } }

@(export, link_name="versabench_dbms_insert_entry")
versabench_dbms_insert_entry :: proc "c" (input: [^]i64,length: c.size_t,output: [^]u8,output_capacity: c.size_t) -> i64 {
	if input == nil || length < 11 || length > 105 do return -1
	depthv:=input[0]; new_id:=input[1]; if depthv < 0 || depthv > MAX_DEPTH || new_id < 0 || new_id >= 32 do return -1
	depth:=int(depthv); incoming: [8]i64; for i := 0; i < 8; i += 1 { incoming[i]=input[2+i] }; if !valid_box(incoming) do return -1
	branches: [MAX_DEPTH][MAX_CHILDREN][8]i64; counts: [MAX_DEPTH]int; pos:=10
	for level := 0; level < depth; level += 1 { if pos >= int(length) do return -1; cv:=input[pos]; pos += 1; if cv < 1 || cv > MAX_CHILDREN || pos+int(cv)*8 > int(length) do return -1; counts[level]=int(cv); for i := 0; i < counts[level]; i += 1 { b: [8]i64; for j := 0; j < 8; j += 1 { b[j]=input[pos+j] }; pos += 8; if !valid_box(b) do return -1; branches[level][i]=b } }
	if pos >= int(length) do return -1; lv:=input[pos]; pos += 1; if lv < 0 || lv > MAX_LEAF || (depth > 0 && lv == 0) || pos+int(lv)*9 > int(length) do return -1
	leaf_count:=int(lv); leaves: [MAX_LEAF][8]i64; ids: [MAX_LEAF]i64; seen: [32]bool
	for i := 0; i < leaf_count; i += 1 { for j := 0; j < 8; j += 1 { leaves[i][j]=input[pos+j] }; pos += 8; ids[i]=input[pos]; pos += 1; if !valid_box(leaves[i]) || ids[i] < 0 || ids[i] >= 32 || seen[int(ids[i])] do return -1; seen[int(ids[i])]=true }
	if pos != int(length) || seen[int(new_id)] do return -1
	choices: [MAX_DEPTH]int
	for level := 0; level < depth; level += 1 { best:=i64(65536); for i := 0; i < counts[level]; i += 1 { joined: [8]i64; for d := 0; d < 4; d += 1 { joined[d]=min(branches[level][i][d],incoming[d]); joined[4+d]=max(branches[level][i][4+d],incoming[4+d]) }; penalty:=volume(joined)-volume(branches[level][i]); if penalty < best { best=penalty; choices[level]=i } } }
	if depth > 0 { pre:=union_boxes(leaves[:leaf_count]); for rev := 0; rev < depth; rev += 1 { level:=depth-1-rev; if !same_box(branches[level][choices[level]],pre) do return -1; pre=union_boxes(branches[level][:counts[level]]) } }
	staged: [MAX_LEAF+1][8]i64; for i := 0; i < leaf_count; i += 1 { staged[i]=leaves[i] }; staged[leaf_count]=incoming; child:=union_boxes(staged[:leaf_count+1])
	result: [MAX_WORDS]i64; outn:=0; result[outn]=i64(depth); outn += 1; result[outn]=new_id; outn += 1; for i := 0; i < depth; i += 1 { result[outn]=i64(choices[i]); outn += 1 }; for d := 0; d < 8; d += 1 { result[outn]=child[d]; outn += 1 }
	for rev := 0; rev < depth; rev += 1 { level:=depth-1-rev; branches[level][choices[level]]=child; child=union_boxes(branches[level][:counts[level]]); for d := 0; d < 8; d += 1 { result[outn]=child[d]; outn += 1 } }
	bytes:=outn*8; if output == nil || output_capacity < c.size_t(bytes) do return -2; for i := 0; i < outn; i += 1 { write_i64(output,i,result[i]) }; return i64(bytes)
}

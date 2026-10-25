module versabench_dbms_partition_entries

const max_fan = 8
const max_input_length = 1 + 8 * (max_fan + 1)

fn valid_box(v &i64, at int) bool {
	unsafe { for d in 0 .. 4 { if v[at+d] < -8 || v[at+d] > 8 || v[at+4+d] < -8 || v[at+4+d] > 8 || v[at+d] >= v[at+4+d] { return false } } }
	return true
}
fn volume_at(v &i64, at int) i64 { mut p:=i64(1);unsafe{for d in 0 .. 4{p*=v[at+4+d]-v[at+d]}};return p }
fn union_volume(v &i64, left int, right int) i64 {
	mut p:=i64(1)
	unsafe { for d in 0 .. 4 { lo:=if v[left+d]<v[right+d]{v[left+d]}else{v[right+d]};hi:=if v[left+4+d]>v[right+4+d]{v[left+4+d]}else{v[right+4+d]};p*=hi-lo } }
	return p
}
fn penalty(v &i64, seed int, entry int) i64 { return union_volume(v,seed,entry)-volume_at(v,seed) }

@[export: 'versabench_dbms_partition_entries']
pub fn versabench_dbms_partition_entries(values &i64,length usize)i64{
	unsafe{
		if values==nil||length<1||length>usize(max_input_length+1){return -1}
		if values[0]<2||values[0]>max_fan{return -1}
		fan:=int(values[0]);count:=fan+1;if length!=usize(1+8*count){return -1}
		for i in 0..count{if !valid_box(values,1+8*i){return -1}}
		mut seed_a:=0;mut seed_b:=1;mut largest:=union_volume(values,1,9)
		for i in 0..count{for j in i+1..count{candidate:=union_volume(values,1+8*i,1+8*j);if candidate>largest{seed_a=i;seed_b=j;largest=candidate}}}
		a_at:=1+8*seed_a;b_at:=1+8*seed_b;mut size_a:=1;mut size_b:=1;mut mask:=i64(1)<<seed_a
		for i in 0..count{if i==seed_a||i==seed_b{continue};at:=1+8*i
			if size_a<fan&&size_b<fan{if penalty(values,a_at,at)<penalty(values,b_at,at){mask|=i64(1)<<i;size_a++}else{size_b++}}
			else if size_a>=fan&&size_b<fan{size_b++}else if size_b>=fan&&size_a<fan{mask|=i64(1)<<i;size_a++}else{return -1}
		}
		return mask
	}
}

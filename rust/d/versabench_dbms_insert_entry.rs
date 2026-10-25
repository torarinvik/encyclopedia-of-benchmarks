const MAX_DEPTH: usize = 2;
const MAX_CHILDREN: usize = 4;
const MAX_LEAF: usize = 3;
const MAX_WORDS: usize = 28;

fn valid_box(b:&[i64;8])->bool{for d in 0..4{if b[d] < -8||b[d]>8||b[4+d] < -8||b[4+d]>8||b[d]>=b[4+d]{return false;}}true}
fn union_boxes(boxes:&[[i64;8]])->[i64;8]{let mut out=boxes[0];for b in boxes.iter().skip(1){for d in 0..4{out[d]=out[d].min(b[d]);out[4+d]=out[4+d].max(b[4+d]);}}out}
fn volume(b:&[i64;8])->i64{let mut v=1;for d in 0..4{v*=b[4+d]-b[d];}v}
fn same_box(a:&[i64;8],b:&[i64;8])->bool{a==b}
fn write_i64(out:*mut u8,word:usize,value:i64){for b in 0..8{unsafe{*out.add(word*8+b)=((value as u64)>>(8*b)) as u8;}}}

#[no_mangle]
pub unsafe extern "C" fn versabench_dbms_insert_entry(raw:*const i64,length:usize,output:*mut u8,output_capacity:usize)->i64{
    if raw.is_null()||length<11||length>105{return -1;}
    let v=unsafe{std::slice::from_raw_parts(raw,length)};let depthv=v[0];let new_id=v[1];
    if depthv<0||depthv>MAX_DEPTH as i64||new_id<0||new_id>=32{return -1;}
    let depth=depthv as usize;let mut incoming=[0_i64;8];incoming.copy_from_slice(&v[2..10]);if !valid_box(&incoming){return -1;}
    let mut branches=[[[0_i64;8];MAX_CHILDREN];MAX_DEPTH];let mut counts=[0_usize;MAX_DEPTH];let mut seen=[false;32];let mut pos=10;
    for level in 0..depth{if pos>=length{return -1;}let cv=v[pos];pos+=1;if cv<1||cv>MAX_CHILDREN as i64||pos+cv as usize*8>length{return -1;}counts[level]=cv as usize;for i in 0..counts[level]{let mut b=[0_i64;8];b.copy_from_slice(&v[pos..pos+8]);pos+=8;if !valid_box(&b){return -1;}branches[level][i]=b;}}
    if pos>=length{return -1;}let lv=v[pos];pos+=1;if lv<0||lv>MAX_LEAF as i64||(depth>0&&lv==0)||pos+lv as usize*9>length{return -1;}
    let leaf_count=lv as usize;let mut leaf_boxes=[[0_i64;8];MAX_LEAF];let mut leaf_ids=[0_i64;MAX_LEAF];
    for i in 0..leaf_count{leaf_boxes[i].copy_from_slice(&v[pos..pos+8]);pos+=8;leaf_ids[i]=v[pos];pos+=1;if !valid_box(&leaf_boxes[i])||leaf_ids[i]<0||leaf_ids[i]>=32||seen[leaf_ids[i] as usize]{return -1;}seen[leaf_ids[i] as usize]=true;}
    if pos!=length||seen[new_id as usize]{return -1;}
    let mut choices=[0_usize;MAX_DEPTH];
    for level in 0..depth{let mut best=i64::MAX;for i in 0..counts[level]{let mut joined=[0_i64;8];for d in 0..4{joined[d]=branches[level][i][d].min(incoming[d]);joined[4+d]=branches[level][i][4+d].max(incoming[4+d]);}let p=volume(&joined)-volume(&branches[level][i]);if p<best{best=p;choices[level]=i;}}}
    if depth>0{let mut pre=union_boxes(&leaf_boxes[..leaf_count]);for rev in (0..depth).rev(){let level=rev;if !same_box(&branches[level][choices[level]],&pre){return -1;}pre=union_boxes(&branches[level][..counts[level]]);}}
    let mut staged=[[0_i64;8];MAX_LEAF+1];for i in 0..leaf_count{staged[i]=leaf_boxes[i];}staged[leaf_count]=incoming;
    let mut child=union_boxes(&staged[..leaf_count+1]);let mut result=[0_i64;MAX_WORDS];let mut outn=0;
    result[outn]=depth as i64;outn+=1;result[outn]=new_id;outn+=1;for i in 0..depth{result[outn]=choices[i] as i64;outn+=1;}for d in 0..8{result[outn]=child[d];outn+=1;}
    for rev in (0..depth).rev(){let level=rev;branches[level][choices[level]]=child;child=union_boxes(&branches[level][..counts[level]]);for d in 0..8{result[outn]=child[d];outn+=1;}}
    let bytes=outn*8;if output.is_null()||output_capacity<bytes{return -2;}for i in 0..outn{write_i64(output,i,result[i]);}bytes as i64
}

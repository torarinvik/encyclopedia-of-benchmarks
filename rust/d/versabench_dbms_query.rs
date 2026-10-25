const MAX_NODES: usize = 7;
const MAX_ENTRIES: usize = 4;
const MAX_RECORDS: usize = 16;

#[derive(Clone, Copy)]
struct Entry { lo: [i64;4], hi: [i64;4], reference: i64 }
#[derive(Clone, Copy)]
struct Node { level: i64, count: usize, entries: [Entry;MAX_ENTRIES] }
const EMPTY_ENTRY: Entry = Entry { lo:[0;4], hi:[0;4], reference:0 };
const EMPTY_NODE: Node = Node { level:0, count:0, entries:[EMPTY_ENTRY;MAX_ENTRIES] };

fn valid_box(lo:&[i64;4],hi:&[i64;4])->bool {
    for d in 0..4 { if lo[d] < -8 || lo[d] > 8 || hi[d] < -8 || hi[d] > 8 || lo[d] >= hi[d] {return false;} }
    true
}
fn intersects(e:&Entry,lo:&[i64;4],hi:&[i64;4])->bool {
    for d in 0..4 {if lo[d]>e.hi[d]||e.lo[d]>hi[d]{return false;}}
    true
}
fn write_i64(out:*mut u8,word:usize,value:i64){
    for b in 0..8 { unsafe {*out.add(word*8+b)=((value as u64)>>(8*b)) as u8;} }
}

#[no_mangle]
pub unsafe extern "C" fn versabench_dbms_query(raw:*const i64,length:usize,output:*mut u8,output_capacity:usize)->i64 {
    if raw.is_null()||length<10||length>277{return -1;}
    let v=unsafe{std::slice::from_raw_parts(raw,length)};
    let nn=v[0];let rootv=v[1];if nn<1||nn>MAX_NODES as i64||rootv<0||rootv>=nn{return -1;}
    let n=nn as usize;let root=rootv as usize;
    let mut qlo=[0_i64;4];let mut qhi=[0_i64;4];for d in 0..4{qlo[d]=v[2+d];qhi[d]=v[6+d];}
    if !valid_box(&qlo,&qhi){return -1;}
    let mut nodes=[EMPTY_NODE;MAX_NODES];let mut parents=[0_usize;MAX_NODES];let mut seen=[false;32];
    let mut leaf_total=0_usize;let mut pos=10_usize;
    for ni in 0..n{
        if pos+2>length{return -1;}let level=v[pos];let countv=v[pos+1];pos+=2;
        if level<0||level>2||countv<1||countv>MAX_ENTRIES as i64||pos+countv as usize*9>length{return -1;}
        let count=countv as usize;nodes[ni].level=level;nodes[ni].count=count;
        for ei in 0..count{
            let mut lo=[0_i64;4];let mut hi=[0_i64;4];for d in 0..4{lo[d]=v[pos+d];}pos+=4;for d in 0..4{hi[d]=v[pos+d];}pos+=4;
            let reference=v[pos];pos+=1;if !valid_box(&lo,&hi){return -1;}
            nodes[ni].entries[ei]=Entry{lo,hi,reference};
            if level==0{if reference<0||reference>=32||seen[reference as usize]||leaf_total>=MAX_RECORDS{return -1;}seen[reference as usize]=true;leaf_total+=1;}
            else{if reference<0||reference>=nn{return -1;}parents[reference as usize]+=1;if parents[reference as usize]>1{return -1;}}
        }
    }
    if pos!=length||parents[root]!=0{return -1;}
    for ni in 0..n{
        if ni!=root&&parents[ni]!=1{return -1;}if nodes[ni].level==0{continue;}
        for ei in 0..nodes[ni].count{
            let branch=nodes[ni].entries[ei];let child=&nodes[branch.reference as usize];
            if child.level!=nodes[ni].level-1{return -1;}
            for ce in 0..child.count{for d in 0..4{if branch.lo[d]>child.entries[ce].lo[d]||branch.hi[d]<child.entries[ce].hi[d]{return -1;}}}
        }
    }
    let mut stack=[0_usize;MAX_NODES];let mut top=1_usize;stack[0]=root;
    let mut hits=[0_i64;MAX_RECORDS];let mut hit_count=0_usize;
    while top>0{top-=1;let ni=stack[top];let node=nodes[ni];
        if node.level==0{for ei in 0..node.count{let e=node.entries[ei];if intersects(&e,&qlo,&qhi){hits[hit_count]=e.reference;hit_count+=1;}}}
        else{for rev in (0..node.count).rev(){let e=node.entries[rev];if intersects(&e,&qlo,&qhi){stack[top]=e.reference as usize;top+=1;}}}
    }
    let bytes=hit_count*8;if output.is_null()||output_capacity<bytes{return -2;}
    for i in 0..hit_count{write_i64(output,i,hits[i]);}bytes as i64
}

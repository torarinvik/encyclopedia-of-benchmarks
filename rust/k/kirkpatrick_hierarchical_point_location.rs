const MAX_VERTICES: usize = 16;
const MAX_LEVELS: usize = 4;
const MAX_FACES: usize = 8;
const MAX_INPUT: usize = 268;

fn cross(ax:i64,ay:i64,bx:i64,by:i64,cx:i64,cy:i64)->i64{(bx-ax)*(cy-ay)-(by-ay)*(cx-ax)}
fn on_segment(ax:i64,ay:i64,bx:i64,by:i64,px:i64,py:i64)->bool{
    cross(ax,ay,bx,by,px,py)==0&&px>=ax.min(bx)&&px<=ax.max(bx)&&py>=ay.min(by)&&py<=ay.max(by)
}
fn inside(q:[i64;2],t:[i64;3],xy:&[[i64;2];MAX_VERTICES])->bool{
    let a=xy[t[0] as usize];let b=xy[t[1] as usize];let c=xy[t[2] as usize];
    cross(a[0],a[1],b[0],b[1],q[0],q[1])>0&&cross(b[0],b[1],c[0],c[1],q[0],q[1])>0&&cross(c[0],c[1],a[0],a[1],q[0],q[1])>0
}
fn boundary(q:[i64;2],t:[i64;3],xy:&[[i64;2];MAX_VERTICES])->bool{
    for e in 0..3{let a=xy[t[e] as usize];let b=xy[t[(e+1)%3] as usize];if on_segment(a[0],a[1],b[0],b[1],q[0],q[1]){return true;}}false
}
fn segment_intersects(a:[i64;2],b:[i64;2],c:[i64;2],d:[i64;2])->bool{
    let o1=cross(a[0],a[1],b[0],b[1],c[0],c[1]);let o2=cross(a[0],a[1],b[0],b[1],d[0],d[1]);
    let o3=cross(c[0],c[1],d[0],d[1],a[0],a[1]);let o4=cross(c[0],c[1],d[0],d[1],b[0],b[1]);
    (o1==0&&on_segment(a[0],a[1],b[0],b[1],c[0],c[1]))||(o2==0&&on_segment(a[0],a[1],b[0],b[1],d[0],d[1]))||
    (o3==0&&on_segment(c[0],c[1],d[0],d[1],a[0],a[1]))||(o4==0&&on_segment(c[0],c[1],d[0],d[1],b[0],b[1]))||
    (o1*o2<0&&o3*o4<0)
}
fn closed_inside(p:[i64;2],t:[i64;3],xy:&[[i64;2];MAX_VERTICES])->bool{
    for e in 0..3{let a=xy[t[e] as usize];let b=xy[t[(e+1)%3] as usize];if cross(a[0],a[1],b[0],b[1],p[0],p[1])<0{return false;}}true
}
fn intersects(a:[i64;3],b:[i64;3],xy:&[[i64;2];MAX_VERTICES])->bool{
    for i in 0..3{if closed_inside(xy[a[i] as usize],b,xy){return true;}if closed_inside(xy[b[i] as usize],a,xy){return true;}}
    for i in 0..3{for j in 0..3{let p=xy[a[i] as usize];let q=xy[a[(i+1)%3] as usize];let r=xy[b[j] as usize];let s=xy[b[(j+1)%3] as usize];if segment_intersects(p,q,r,s){return true;}}}false
}
unsafe fn put64(out:*mut u8,pos:usize,value:i64){let bits=value as u64;for j in 0..8{*out.add(pos+j)=(bits>>(8*j)) as u8;}}

#[no_mangle]
pub unsafe extern "C" fn kirkpatrick_hierarchical_point_location(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<14||length>MAX_INPUT{return -1;}
    let nv=*input;let nl=*input.add(1);let q=[*input.add(2),*input.add(3)];
    if nv<3||nv>MAX_VERTICES as i64||nl<1||nl>MAX_LEVELS as i64||q[0]< -1000||q[0]>1000||q[1]< -1000||q[1]>1000{return -1;}
    let mut xy=[[0i64;2];MAX_VERTICES];let mut faces=[[[0i64;3];MAX_FACES];MAX_LEVELS];let mut face_count=[0usize;MAX_LEVELS];
    let mut cand_count=[[0usize;MAX_FACES];MAX_LEVELS];let mut cand_ids=[[[0usize;MAX_FACES];MAX_FACES];MAX_LEVELS];let mut pos=4usize;
    for v in 0..nv as usize{xy[v]=[*input.add(pos),*input.add(pos+1)];pos+=2;if xy[v][0]< -1000||xy[v][0]>1000||xy[v][1]< -1000||xy[v][1]>1000{return -1;}}
    for level in 0..nl as usize{
        if pos>=length{return -1;}let count=*input.add(pos);pos+=1;if count<1||count>MAX_FACES as i64||(level==0&&count!=1){return -1;}face_count[level]=count as usize;
        for f in 0..count as usize{if pos+3>length{return -1;}for k in 0..3{let id=*input.add(pos);pos+=1;if id<0||id>=nv{return -1;}faces[level][f][k]=id;}
            let t=faces[level][f];if t[0]==t[1]||t[0]==t[2]||t[1]==t[2]{return -1;}let a=xy[t[0] as usize];let b=xy[t[1] as usize];let c=xy[t[2] as usize];if cross(a[0],a[1],b[0],b[1],c[0],c[1])<=0{return -1;}}
        if level+1<nl as usize{for f in 0..count as usize{if pos>=length{return -1;}let cc=*input.add(pos);pos+=1;if cc<1||cc>MAX_FACES as i64||pos+cc as usize>length{return -1;}cand_count[level][f]=cc as usize;
            for j in 0..cc as usize{let id=*input.add(pos);pos+=1;if id<0||id>=MAX_FACES as i64||(j>0&&id<=cand_ids[level][f][j-1] as i64){return -1;}cand_ids[level][f][j]=id as usize;}}}
    }
    if pos!=length{return -1;}
    let levels=nl as usize;
    for level in 0..(levels-1){for f in 0..face_count[level]{for j in 0..cand_count[level][f]{let child=cand_ids[level][f][j];if child>=face_count[level+1]||!intersects(faces[level][f],faces[level+1][child],&xy){return -1;}}}}
    for level in 0..nl as usize{let mut hits=0;for f in 0..face_count[level]{if boundary(q,faces[level][f],&xy){return -1;}if inside(q,faces[level][f],&xy){hits+=1;}}if hits!=1{return -1;}}
    let mut face=0usize;let mut predicates=1i64;
    for level in 0..(levels-1){let mut found=None;for j in 0..cand_count[level][face]{let child=cand_ids[level][face][j];predicates+=1;if inside(q,faces[level+1][child],&xy){found=Some(child);break;}}if found.is_none(){return -1;}face=found.unwrap();}
    if output.is_null()||capacity<16{return -2;}let mut staged=[0u8;16];put64(staged.as_mut_ptr(),0,face as i64);put64(staged.as_mut_ptr(),8,predicates);for i in 0..16{*output.add(i)=staged[i];}16
}

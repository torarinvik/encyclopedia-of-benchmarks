const MAX_INPUT: usize = 67;
const MAX_OUTPUT: usize = 504;
const MAX_H: usize = 63;

struct Context<'a> {
    concave: &'a [i64], arbitrary: &'a [i64],
    y_min: [usize; MAX_H], y_max: [usize; MAX_H],
    x_min: [usize; 32], x_max: [usize; 32], result: [i64; MAX_H],
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

fn block_rows(c: &mut Context<'_>, x1:usize,x2:usize,y1:usize,y2:usize,
              row1:usize,row2:usize,q1:usize,q2:usize) {
    if row1>row2{return;}
    let mid=row1+(row2-row1)/2; let x=x1+mid;
    let mut best=i64::MAX; let mut best_q=q1;
    for q in q1..=q2 {let y=y2-q;let value=c.arbitrary[y]+c.concave[x-y];if value<best{best=value;best_q=q;}}
    if best<c.result[x]{c.result[x]=best;}
    if row1<mid{block_rows(c,x1,x2,y1,y2,row1,mid-1,q1,best_q);}
    if mid<row2{block_rows(c,x1,x2,y1,y2,mid+1,row2,best_q,q2);}
}

fn scan_rectangle(c:&mut Context<'_>,x1:usize,x2:usize,y1:usize,y2:usize){
    for x in x1..=x2 {let lo=c.y_min[x].max(y1);let hi=c.y_max[x].min(y2);if lo<=hi{
        for y in lo..=hi{let v=c.arbitrary[y]+c.concave[x-y];if v<c.result[x]{c.result[x]=v;}}
    }}
}

fn partition(c:&mut Context<'_>,x1:usize,x2:usize,y1:usize,y2:usize){
    if x1>x2||y1>y2{return;}
    if c.y_max[x1]>=y2&&y1>=c.y_min[x2]{block_rows(c,x1,x2,y1,y2,0,x2-x1,0,y2-y1);return;}
    if (x2-x1)*(y2-y1)<1000{scan_rectangle(c,x1,x2,y1,y2);return;}
    if x2-x1>y2-y1{let mid=(x1+x2)/2;let ly=c.y_max[mid].min(y2);if y1<=ly{partition(c,x1,mid,y1,ly);}let ry=c.y_min[mid].max(y1);if ry<=y2{partition(c,mid+1,x2,ry,y2);}}
    else{let mid=(y1+y2)/2;let lx=c.x_max[mid].min(x2);if x1<=lx{partition(c,x1,lx,y1,mid);}let rx=c.x_min[mid].max(x1);if rx<=x2{partition(c,rx,x2,mid+1,y2);}}
}

#[no_mangle]
pub unsafe extern "C" fn min_plus_convolution_concave_arbitrary(
    input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<4||length>MAX_INPUT{return -1;}
    let words=std::slice::from_raw_parts(input,length);let n0=words[0];let m0=words[1];
    if !(1..=32).contains(&n0)||!(1..=32).contains(&m0){return -1;}
    let n=n0 as usize;let m=m0 as usize;if length!=2+n+m{return -1;}
    let a=&words[2..2+n];let b=&words[2+n..];
    if words[2..].iter().any(|&v|v<0||v>1_000_000_000){return -1;}
    for i in 0..n.saturating_sub(2){if a[i+1]-a[i]<a[i+2]-a[i+1]{return -1;}}
    let h=n+m-1;let bytes=8*h;if bytes>MAX_OUTPUT{return -1;}if output.is_null()||capacity<bytes{return -2;}
    let mut c=Context{concave:a,arbitrary:b,y_min:[0;MAX_H],y_max:[0;MAX_H],x_min:[0;32],x_max:[0;32],result:[i64::MAX;MAX_H]};
    for x in 0..h{c.y_min[x]=if x>=n{x-n+1}else{0};c.y_max[x]=x.min(m-1);}
    for y in 0..m{c.x_min[y]=y;c.x_max[y]=n-1+y;}
    partition(&mut c,0,h-1,0,m-1);
    for i in 0..h{store_i64_le(output,8*i,c.result[i]);}
    bytes as i64
}

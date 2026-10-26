#[no_mangle]
pub unsafe extern "C" fn graphai_frontier_sampler(input:*const f64,length:usize,output:*mut f64,capacity:usize)->i64{
    const N:usize=8;const M:usize=24;const R:usize=4;const MAX_INPUT:usize=4+N+M+22*R;
    if input.is_null()||length<3||length>MAX_INPUT{return -1;}for q in 0..length{if !(*input.add(q)).is_finite(){return -1;}}
    let nv=*input;let mv=*input.add(1);let rv=*input.add(2);if nv.fract()!=0.0||mv.fract()!=0.0||rv.fract()!=0.0||nv<1.0||nv>N as f64||mv<0.0||mv>M as f64||rv<1.0||rv>R as f64{return -1;}
    let n=nv as usize;let m=mv as usize;let r=rv as usize;let required=22*r;if length!=4+n+m+22*r{return -1;}
    let root_at=3;let row_at=root_at+r;let col_at=row_at+n+1;let choice_at=col_at+m;let mut rows=[0usize;N+1];let mut cols=[0usize;M];let mut front=[0usize;R*12];let mut next=[0usize;R*12];let mut staged=[0.0f64;R*22];
    for i in 0..r{let x=*input.add(root_at+i);if x.fract()!=0.0||x<0.0||x>=n as f64{return -1;}front[i]=x as usize;staged[i]=x;}
    if *input.add(row_at)!=0.0||*input.add(col_at-1)!=m as f64{return -1;}
    for i in 0..=n{let x=*input.add(row_at+i);if x.fract()!=0.0||x<0.0||x>m as f64{return -1;}rows[i]=x as usize;if i>0&&rows[i]<rows[i-1]{return -1;}}
    for e in 0..m{let x=*input.add(col_at+e);if x.fract()!=0.0||x<0.0||x>=n as f64{return -1;}cols[e]=x as usize;}
    if output.is_null()||capacity<required{return -2;}
    let fanouts=[3usize,2,2];let mut front_size=r;let mut choice=0usize;let mut out_at=r;
    for fanout in fanouts{let next_size=front_size*fanout;for i in 0..front_size{let parent=front[i];let begin=rows[parent];let degree=rows[parent+1]-begin;if degree==0{return -1;}for j in 0..fanout{let x=*input.add(choice_at+choice);choice+=1;if x.fract()!=0.0||x<0.0||x>=degree as f64{return -1;}let v=cols[begin+x as usize];next[i*fanout+j]=v;staged[out_at]=v as f64;out_at+=1;}}
        for i in 0..next_size{front[i]=next[i];}front_size=next_size;}
    if choice!=21*r||out_at!=required{return -1;}for q in 0..required{*output.add(q)=staged[q];}required as i64
}

const MAX_SAMPLES:usize=8;const MAX_FEATURES:usize=4;const MAX_QUERIES:usize=4;const MAX_INPUT:usize=62;const MAX_OUTPUT:usize=25;
fn integer_range(x:f64,lo:i32,hi:i32)->bool{x.is_finite()&&x>=lo as f64&&x<=hi as f64&&x.fract()==0.0}
fn rate_ok(x:f64)->bool{x==0.25||x==0.5||x==0.75||x==1.0}
fn row_score(w:&[f64;15],base:usize,row:&[f64],row_base:usize,width:usize)->f64{let mut score=0.0;for j in 0..width{score+=w[base+j]*row[row_base+j];}score}

#[no_mangle]
pub unsafe extern "C" fn perceptron_r(input:*const f64,length:usize,output:*mut f64,capacity:usize)->i64{
    if input.is_null()||length<8||length>MAX_INPUT{return -1;}
    let v=unsafe{std::slice::from_raw_parts(input,length)};if v.iter().any(|x|!x.is_finite()){return -1;}
    if !rate_ok(v[0])||!integer_range(v[1],1,12)||!integer_range(v[2],2,8)||!integer_range(v[3],1,4){return -1;}
    let rate=v[0];let epochs=v[1] as usize;let n=v[2] as usize;let f=v[3] as usize;let labels_at=4+n*f;let qidx=labels_at+n;
    if length<=qidx||!integer_range(v[qidx],1,4){return -1;}let q=v[qidx] as usize;
    if length!=qidx+1+q*f||length>61{return -1;}
    let mut x=[0.0;32];let mut labels=[0.0;8];let mut queries=[0.0;16];
    for i in 0..n*f{let a=v[4+i];if !integer_range(a,-2,2){return -1;}x[i]=a;}
    for i in 0..n{let a=v[labels_at+i];if !integer_range(a,-2,2){return -1;}labels[i]=a;}
    for i in 0..q*f{let a=v[qidx+1+i];if !integer_range(a,-2,2){return -1;}queries[i]=a;}
    let mut classes=[0.0;3];let mut class_count=0usize;
    for value in -2..=2{if labels[..n].contains(&(value as f64)){classes[class_count]=value as f64;class_count+=1;}}
    if !(2..=3).contains(&class_count){return -1;}
    let mut rows=[0.0;40];let mut query_rows=[0.0;20];
    for r in 0..n{rows[r*(f+1)]=1.0;for j in 0..f{rows[r*(f+1)+j+1]=x[r*f+j];}}
    for r in 0..q{query_rows[r*(f+1)]=1.0;for j in 0..f{query_rows[r*(f+1)+j+1]=queries[r*f+j];}}
    let mut weights=[0.0;15];
    if class_count==2{
        for _ in 0..epochs{for r in 0..n{let label=if labels[r]==classes[0]{-1.0}else{1.0};let s=row_score(&weights,0,&rows,r*(f+1),f+1);if label*s<=0.0{for j in 0..f+1{weights[j]+=rate*label*rows[r*(f+1)+j];}}}}
    }else{
        for _ in 0..epochs{for r in 0..n{
            let mut scores=[0.0;3];for c in 0..class_count{scores[c]=row_score(&weights,c*(f+1),&rows,r*(f+1),f+1);}
            let mut predicted=0;for c in 1..class_count{if scores[c]>scores[predicted]{predicted=c;}}
            let mut target=0;while target<class_count&&labels[r]!=classes[target]{target+=1;}
            if predicted!=target{for j in 0..f+1{let update=rate*rows[r*(f+1)+j];weights[target*(f+1)+j]+=update;weights[predicted*(f+1)+j]-=update;}}
        }}
    }
    let mut staged=[0.0;MAX_OUTPUT];let mut pos=0usize;staged[pos]=class_count as f64;pos+=1;
    for c in 0..class_count{staged[pos]=classes[c];pos+=1;}
    let parameter_count=if class_count==2{f+1}else{class_count*(f+1)};staged[pos]=parameter_count as f64;pos+=1;
    for j in 0..parameter_count{staged[pos]=weights[j];pos+=1;}staged[pos]=q as f64;pos+=1;
    for r in 0..q{
        let mut predicted=0usize;
        if class_count==2{predicted=if row_score(&weights,0,&query_rows,r*(f+1),f+1)>=0.0{1}else{0};}
        else{let mut scores=[0.0;3];for c in 0..class_count{scores[c]=row_score(&weights,c*(f+1),&query_rows,r*(f+1),f+1);}for c in 1..class_count{if scores[c]>scores[predicted]{predicted=c;}}}
        staged[pos]=classes[predicted];pos+=1;
    }
    if output.is_null()||capacity<pos{return -2;}for i in 0..pos{unsafe{*output.add(i)=staged[i];}}pos as i64
}

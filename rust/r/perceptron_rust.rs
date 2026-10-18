const MAX_SAMPLES:usize=8;const MAX_FEATURES:usize=4;const MAX_QUERIES:usize=4;const MAX_INPUT:usize=62;const MAX_OUTPUT:usize=11;
fn integer_range(x:f64,lo:i32,hi:i32)->bool{x.is_finite()&&x>=lo as f64&&x<=hi as f64&&x.fract()==0.0}
fn rate_ok(x:f64)->bool{x==0.25||x==0.5||x==0.75||x==1.0}

#[no_mangle]
pub unsafe extern "C" fn perceptron_rust(input:*const f64,length:usize,output:*mut f64,capacity:usize)->i64{
    if input.is_null()||length<9||length>MAX_INPUT{return -1;}
    let v=unsafe{std::slice::from_raw_parts(input,length)};if v.iter().any(|x|!x.is_finite()){return -1;}
    if !integer_range(v[0],0,12)||!rate_ok(v[1])||!integer_range(v[2],2,8)||!integer_range(v[3],1,4){return -1;}
    let max_iterations=v[0] as usize;let rate=v[1];let n=v[2] as usize;let f=v[3] as usize;let labels_at=4+n*f;let qidx=labels_at+n;
    if length<=qidx||!integer_range(v[qidx],1,4){return -1;}let q=v[qidx] as usize;
    if length!=qidx+1+q*f||length>61{return -1;}
    let mut x=[0.0;MAX_SAMPLES*MAX_FEATURES];let mut labels=[0.0;MAX_SAMPLES];let mut queries=[0.0;MAX_QUERIES*MAX_FEATURES];
    for i in 0..n*f{let a=v[4+i];if !integer_range(a,-2,2){return -1;}x[i]=a;}
    for i in 0..n{let a=v[labels_at+i];if a!= -1.0&&a!=1.0{return -1;}labels[i]=a;}
    for i in 0..q*f{let a=v[qidx+1+i];if !integer_range(a,-2,2){return -1;}queries[i]=a;}
    let mut weights=[0.0;MAX_FEATURES];let mut bias=0.0;
    for _ in 0..max_iterations{
        let mut misclassified=0usize;
        for r in 0..n{
            let mut score=0.0;for j in 0..f{score+=weights[j]*x[r*f+j];}score+=bias;
            let prediction=if score>=0.0{1.0}else{-1.0};
            if prediction!=labels[r]{misclassified+=1;for j in 0..f{weights[j]+=rate*labels[r]*x[r*f+j];}bias+=rate*labels[r];}
        }
        if misclassified==0{break;}
    }
    let mut staged=[0.0;MAX_OUTPUT];let mut pos=0usize;staged[pos]=f as f64;pos+=1;
    for j in 0..f{staged[pos]=weights[j];pos+=1;}staged[pos]=bias;pos+=1;staged[pos]=q as f64;pos+=1;
    for r in 0..q{let mut score=0.0;for j in 0..f{score+=weights[j]*queries[r*f+j];}score+=bias;staged[pos]=if score>=0.0{1.0}else{-1.0};pos+=1;}
    if output.is_null()||capacity<pos{return -2;}for i in 0..pos{unsafe{*output.add(i)=staged[i];}}pos as i64
}

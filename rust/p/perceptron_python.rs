const MAX_SAMPLES: usize=8;const MAX_FEATURES: usize=4;const MAX_QUERIES: usize=4;const MAX_INPUT: usize=62;const MAX_OUTPUT: usize=12;
const INITIAL_RANDOM:[f64;4]=[0.8444218515250481,0.7579544029403025,0.420571580830845,0.25891675029296335];
fn integer_range(x:f64,lo:i32,hi:i32)->bool{x.is_finite()&&x>=lo as f64&&x<=hi as f64&&x.fract()==0.0}
fn rate_ok(x:f64)->bool{x==0.25||x==0.5||x==0.75||x==1.0}

#[no_mangle]
pub unsafe extern "C" fn perceptron_python(input:*const f64,length:usize,output:*mut f64,capacity:usize)->i64{
    if input.is_null()||length<9||length>MAX_INPUT{return -1;}
    let v=unsafe{std::slice::from_raw_parts(input,length)};if v.iter().any(|x|!x.is_finite()){return -1;}
    if !rate_ok(v[0])||!integer_range(v[1],1,12)||!integer_range(v[2],2,8)||!integer_range(v[3],1,4){return -1;}
    let rate=v[0];let epochs=v[1] as usize;let n=v[2] as usize;let f=v[3] as usize;let labels_at=4+n*f;let qidx=labels_at+n;
    if length<=qidx||!integer_range(v[qidx],1,4){return -1;}let q=v[qidx] as usize;
    if length!=qidx+1+q*f||length>61{return -1;}
    let mut x=[0.0;MAX_SAMPLES*MAX_FEATURES];let mut y=[0.0;MAX_SAMPLES];let mut queries=[0.0;MAX_QUERIES*MAX_FEATURES];
    for i in 0..n*f{let a=v[4+i];if !integer_range(a,-2,2){return -1;}x[i]=a;}
    for i in 0..n{let a=v[labels_at+i];if a!= -1.0&&a!=1.0{return -1;}y[i]=a;}
    for i in 0..q*f{let a=v[qidx+1+i];if !integer_range(a,-2,2){return -1;}queries[i]=a;}
    let mut weights=[0.0;MAX_FEATURES+1];weights[0]= -1.0;for j in 0..f{weights[j+1]=INITIAL_RANDOM[j];}
    let mut epochs_run=0usize;
    for epoch in 0..epochs{
        let mut has_mistake=false;
        for row in 0..n{
            let mut score=0.0;score+=weights[0]*(-1.0);for j in 0..f{score+=weights[j+1]*x[row*f+j];}
            let prediction=if score>=0.0{1.0}else{-1.0};
            if prediction!=y[row]{let error=y[row]-prediction;has_mistake=true;for j in 0..=f{let feature=if j==0{-1.0}else{x[row*f+j-1]};weights[j]+=rate*error*feature;}}
        }
        epochs_run=epoch+1;if !has_mistake{break;}
    }
    let mut staged=[0.0;MAX_OUTPUT];let mut pos=0;staged[pos]=epochs_run as f64;pos+=1;staged[pos]=(f+1) as f64;pos+=1;
    for j in 0..=f{staged[pos]=weights[j];pos+=1;}staged[pos]=q as f64;pos+=1;
    for row in 0..q{let mut score=0.0;score+=weights[0]*(-1.0);for j in 0..f{score+=weights[j+1]*queries[row*f+j];}staged[pos]=if score>=0.0{1.0}else{-1.0};pos+=1;}
    if output.is_null()||capacity<pos{return -2;}for i in 0..pos{unsafe{*output.add(i)=staged[i];}}pos as i64
}

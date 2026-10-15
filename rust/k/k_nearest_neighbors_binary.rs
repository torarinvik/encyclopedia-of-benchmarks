const MAX_DIM: usize=8;
const MAX_POINTS: usize=128;

#[no_mangle]
pub unsafe extern "C" fn k_nearest_neighbors_binary(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<3{return -1;}
    let values=std::slice::from_raw_parts(input,length);let d64=values[0];let n64=values[1];let k64=values[2];
    if !(1..=MAX_DIM as i64).contains(&d64)||!(1..=MAX_POINTS as i64).contains(&n64)||k64<1||k64>n64||k64%2==0||length!=3+d64 as usize+n64 as usize*(d64 as usize+1){return -1;}
    let d=d64 as usize;let n=n64 as usize;let k=k64 as usize;
    if values[3..3+d].iter().any(|&x|!(-1000..=1000).contains(&x)){return -1;}
    let mut distances=[0_i64;MAX_POINTS];let mut labels=[0_i64;MAX_POINTS];
    for point in 0..n{let base=3+d+point*(d+1);let mut sum=0_i64;
        for axis in 0..d{let x=values[base+axis];if !(-1000..=1000).contains(&x){return -1;}let delta=x-values[3+axis];sum+=delta*delta;}
        let label=values[base+d];if label!=0&&label!=1{return -1;}if distances[..point].contains(&sum){return -1;}distances[point]=sum;labels[point]=label;
    }
    for i in 1..n{let (mut distance,mut label)=(distances[i],labels[i]);let mut j=i;while j>0&&distances[j-1]>distance{distances[j]=distances[j-1];labels[j]=labels[j-1];j-=1;}distances[j]=distance;labels[j]=label;}
    let ones:i64=labels[..k].iter().sum();let prediction=if ones>(k/2) as i64{1_i64}else{0_i64};
    if output.is_null()||capacity<8{return -2;}
    std::ptr::copy_nonoverlapping(prediction.to_le_bytes().as_ptr(),output,8);8
}

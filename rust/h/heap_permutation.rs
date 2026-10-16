const MAX_LENGTH: usize = 7;
const BYTES_PER_VALUE: usize = 4;
fn store_i32(output:&mut[u8],offset:usize,value:i32){let bits=value as u32;for b in 0..4{output[offset+b]=(bits>>(8*b))as u8;}}
fn generate(values:&mut[i32;MAX_LENGTH],n:usize,k:usize,output:&mut[u8],rows:&mut usize){
    if k==1{let start=*rows*n*BYTES_PER_VALUE;for j in 0..n{store_i32(output,start+j*BYTES_PER_VALUE,values[j]);}*rows+=1;return;}
    for i in 0..k{let s=if k%2==0{i}else{0};values.swap(s,k-1);generate(values,n,k-1,output,rows);}
}
#[no_mangle]
pub unsafe extern "C" fn heap_permutation(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<1||length>MAX_LENGTH+1{return -1;}let values=std::slice::from_raw_parts(input,length);let nv=values[0];if nv<0||nv>MAX_LENGTH as i64||length!=nv as usize+1{return -1;}let n=nv as usize;
    let mut arr=[0i32;MAX_LENGTH];for i in 0..n{let v=values[i+1];if v<i32::MIN as i64||v>i32::MAX as i64{return -1;}arr[i]=v as i32;}
    let mut permutations=1usize;for f in 2..=n{permutations*=f;}let required=permutations*n*BYTES_PER_VALUE;if capacity<required||(required!=0&&output.is_null()){return -2;}if n==0{return 1;}
    let out=std::slice::from_raw_parts_mut(output,required);let mut rows=0;generate(&mut arr,n,n,out,&mut rows);rows as i64
}

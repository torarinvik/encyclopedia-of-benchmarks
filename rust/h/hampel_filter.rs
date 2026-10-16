/// Three-sample Java Hampel filter using its default threshold 3.0.
fn insert_sorted(a:&mut [f64;3],size:&mut usize,value:f64){let mut p=0;while p<*size&&a[p]<value{p+=1}for j in (p..*size).rev(){a[j+1]=a[j]}a[p]=value;*size+=1;}
fn remove_sorted(a:&mut [f64;3],size:&mut usize,value:f64){let mut p=0;while p<*size&&a[p]!=value{p+=1}if p==*size{return}for j in p+1..*size{a[j-1]=a[j]}*size-=1;}
fn median(a:&[f64;3],size:usize)->f64{let m=size/2;if size%2==1{a[m]}else{0.5*(a[m-1]+a[m])}}
fn mad(a:&[f64;3],size:usize,med:f64)->f64{let mut split=0;while split<size&&a[split]<=med{split+=1}let mut left=split as isize-1;let mut right=split;let mut d=[0.0;3];for i in 0..size{let take=right>=size||(left>=0&&med-a[left as usize]<=a[right]-med);if take{d[i]=med-a[left as usize];left-=1}else{d[i]=a[right]-med;right+=1}}let m=size/2;if size%2==1{d[m]}else{0.5*(d[m-1]+d[m])}}
fn put(out:&mut[u8],at:usize,value:i64){out[at..at+8].copy_from_slice(&value.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn hampel_filter(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<1{return -1}let n64=*input;if !(0..=128).contains(&n64)||length!=n64 as usize+1{return -1}let n=n64 as usize;let x=std::slice::from_raw_parts(input,length);if x[1..].iter().any(|v|!(-1000..=1000).contains(v)){return -1}if capacity<n*8||(n>0&&output.is_null()){return -2}if n==0{return 0}
 let out=std::slice::from_raw_parts_mut(output,n*8);let mut arrival=[0.0;3];let mut sorted=[0.0;3];let mut size=0;let mut oldest=0;
 for i in 0..n{let value=x[i+1] as f64;if size==3{remove_sorted(&mut sorted,&mut size,arrival[oldest])}insert_sorted(&mut sorted,&mut size,value);arrival[oldest]=value;oldest=(oldest+1)%3;let med=median(&sorted,size);let mdev=mad(&sorted,size,med);let filtered=if (value-med).abs()>3.0*1.4826*mdev{med}else{value};put(out,i*8,filtered as i64)}(n*8)as i64
}

const MAX_COUNT: usize = 64;
const MAX_INPUT_LENGTH: usize = 66;

fn less_float(left: f32, right: f32) -> bool { left.total_cmp(&right).is_lt() }
fn push_max(heap: &mut [f32; MAX_COUNT], count: &mut usize, value: f32) { let mut p=*count;*count+=1;while p>0&&less_float(heap[(p-1)/2],value){let parent=(p-1)/2;heap[p]=heap[parent];p=parent;}heap[p]=value; }
fn pop_max(heap: &mut [f32; MAX_COUNT], count: &mut usize) -> f32 { let result=heap[0];*count-=1;let value=heap[*count];if *count==0{return result;}let mut p=0;while 2*p+1<*count{let mut child=2*p+1;if child+1<*count&&less_float(heap[child],heap[child+1]){child+=1;}if !less_float(value,heap[child]){break;}heap[p]=heap[child];p=child;}heap[p]=value;result }
fn push_min(heap: &mut [f32; MAX_COUNT], count: &mut usize, value: f32) { let mut p=*count;*count+=1;while p>0&&less_float(value,heap[(p-1)/2]){let parent=(p-1)/2;heap[p]=heap[parent];p=parent;}heap[p]=value; }
fn pop_min(heap: &mut [f32; MAX_COUNT], count: &mut usize) -> f32 { let result=heap[0];*count-=1;let value=heap[*count];if *count==0{return result;}let mut p=0;while 2*p+1<*count{let mut child=2*p+1;if child+1<*count&&less_float(heap[child+1],heap[child]){child+=1;}if !less_float(heap[child],value){break;}heap[p]=heap[child];p=child;}heap[p]=value;result }

#[no_mangle]
pub unsafe extern "C" fn median_of_running_array_float(input: *const f64, length: usize,
                                                        output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length); let count_value=values[0];
    if !count_value.is_finite()||count_value<1.0||count_value>MAX_COUNT as f64||count_value.fract()!=0.0||length!=1+count_value as usize{return -1;}
    let count=count_value as usize;let mut lower=[0.0f32;MAX_COUNT];let mut upper=[0.0f32;MAX_COUNT];let mut medians=[0.0f32;MAX_COUNT];let mut lc=0usize;let mut uc=0usize;
    for i in 0..count{let sample=values[i+1];if !sample.is_finite()||sample < -1_000_000.0||sample>1_000_000.0{return -1;}let x=sample as f32;if x as f64!=sample||(sample==0.0&&(x.to_bits()>>31)!=(sample.to_bits()>>63) as u32){return -1;}
        if uc>0&&less_float(x,upper[0]){push_max(&mut lower,&mut lc,x);}else{push_min(&mut upper,&mut uc,x);}
        if lc>uc+1{push_min(&mut upper,&mut uc,pop_max(&mut lower,&mut lc));}else if uc>lc+1{push_max(&mut lower,&mut lc,pop_min(&mut upper,&mut uc));}
        medians[i]=if lc>uc{lower[0]}else if uc>lc{upper[0]}else{let sum:f32=lower[0]+upper[0];let average:f32=sum/2.0f32;average};}
    if output.is_null()||capacity<count{return -2;}for i in 0..count{*output.add(i)=medians[i] as f64;}count as i64
}

const MAX_ARRAY_LENGTH:usize=4096;
fn sift_down(v:&mut [i64],mut root:usize,end:usize){while root<end/2{let mut child=root*2+1;if child+1<end&&v[child]<v[child+1]{child+=1;}if v[root]>=v[child]{break;}v.swap(root,child);root=child;}}

#[no_mangle]
pub extern "C" fn wave_sort(input:*const i64,length:usize,output:*mut u8,output_capacity:usize)->i64{
    if length>MAX_ARRAY_LENGTH||(length!=0&&input.is_null()){return -1;}
    let mut values=[0i64;MAX_ARRAY_LENGTH];for i in 0..length{let v=unsafe{*input.add(i)};if v<i32::MIN as i64||v>i32::MAX as i64{return -1;}values[i]=v;}
    let bytes=length*4;if output_capacity<bytes||(bytes!=0&&output.is_null()){return -2;}
        for start in (0..length/2).rev(){sift_down(&mut values[..length],start,length);}
    for end in (2..=length).rev(){values.swap(0,end-1);sift_down(&mut values[..length],0,end-1);}
    for i in (0..length.saturating_sub(1)).step_by(2){values.swap(i,i+1);}

    for i in 0..length{let bits=values[i] as i32 as u32;for b in 0..4{unsafe{*output.add(i*4+b)=(bits>>(b*8)) as u8;}}}
    length as i64
}

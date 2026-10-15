const MAX_ARRAY_LENGTH:usize=4096;

#[no_mangle]
pub extern "C" fn wiggle_sort(input:*const i64,length:usize,output:*mut u8,output_capacity:usize)->i64{
    if length>MAX_ARRAY_LENGTH||(length!=0&&input.is_null()){return -1;}
    let mut values=[0i64;MAX_ARRAY_LENGTH];for i in 0..length{let v=unsafe{*input.add(i)};if v<i32::MIN as i64||v>i32::MAX as i64{return -1;}values[i]=v;}
    let bytes=length*4;if output_capacity<bytes||(bytes!=0&&output.is_null()){return -2;}
        for i in 1..length{if (i%2==1&&values[i-1]>values[i])||(i%2==0&&values[i-1]<values[i]){values.swap(i,i-1);}}

    for i in 0..length{let bits=values[i] as i32 as u32;for b in 0..4{unsafe{*output.add(i*4+b)=(bits>>(b*8)) as u8;}}}
    length as i64
}

const MAX_MACHINES:usize=3;const MAX_OLD_JOBS:usize=8;const MAX_INPUT:usize=20;const MAX_OUTPUT:usize=88;
fn optimum(machines:usize,sizes:&[i64],jobs:usize)->i64{let mut assignments=1u64;for _ in 0..jobs{assignments*=machines as u64;}let mut best:i64=sizes[..jobs].iter().sum();for code in 0..assignments{let mut loads=[0i64;MAX_MACHINES];let mut remaining=code;for size in sizes.iter().take(jobs){let target=(remaining%machines as u64)as usize;remaining/=machines as u64;loads[target]+=*size;}let makespan=*loads[..machines].iter().max().unwrap();if makespan<best{best=makespan;}}best}
unsafe fn put64(out:*mut u8,pos:usize,value:i64){let bits=value as u64;for j in 0..8{*out.add(pos+j)=(bits>>(8*j))as u8;}}

#[no_mangle]
pub unsafe extern "C" fn robust_scheduling_single_arrival_migration(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<6||length>MAX_INPUT{return -1;}
    let m64=*input;let n64=*input.add(1);let claimed=*input.add(2);let new_size=*input.add(3);
    if m64<2||m64>MAX_MACHINES as i64||n64<1||n64>MAX_OLD_JOBS as i64||claimed<1||new_size<1||new_size>20||length!=4+2*n64 as usize{return -1;}
    let m=m64 as usize;let n=n64 as usize;let mut sizes=[0i64;MAX_OLD_JOBS+1];let mut assignment=[0usize;MAX_OLD_JOBS+1];let mut loads=[0i64;MAX_MACHINES];
    for i in 0..n{let size=*input.add(4+2*i);let machine=*input.add(5+2*i);if size<1||size>20||machine<0||machine>=m64{return -1;}sizes[i]=size;assignment[i]=machine as usize;loads[machine as usize]+=size;}
    sizes[n]=new_size;let exact=optimum(m,&sizes,n+1);if exact!=claimed{return -1;}let mut moved=0i64;
    if 2*new_size<=exact{let mut target=0;for machine in 1..m{if loads[machine]<loads[target]{target=machine;}}assignment[n]=target;loads[target]+=new_size;}
    else{let mut source=None;for machine in 0..m{let mut eligible=true;let mut volume=0i64;for i in 0..n{if assignment[i]==machine{if 2*sizes[i]>exact{eligible=false;}volume+=sizes[i];}}if eligible&&volume>=new_size{source=Some(machine);break;}}
        let source=match source{Some(value)=>value,None=>return -1};let mut removed=[false;MAX_OLD_JOBS];let mut volume=0i64;
        for i in 0..n{if assignment[i]==source{removed[i]=true;volume+=sizes[i];loads[source]-=sizes[i];if volume>=new_size{break;}}}
        if volume<new_size{return -1;}assignment[n]=source;loads[source]+=new_size;
        for i in 0..n{if removed[i]{let mut target=0;for machine in 1..m{if loads[machine]<loads[target]{target=machine;}}assignment[i]=target;loads[target]+=sizes[i];if target!=source{moved+=sizes[i];}}}
    }
    let bytes=8*(n+3);if output.is_null()||capacity<bytes{return -2;}let mut staged=[0u8;MAX_OUTPUT];put64(staged.as_mut_ptr(),0,exact);put64(staged.as_mut_ptr(),8,moved);for i in 0..n+1{put64(staged.as_mut_ptr(),8*(i+2),assignment[i] as i64);}for i in 0..bytes{*output.add(i)=staged[i];}bytes as i64
}

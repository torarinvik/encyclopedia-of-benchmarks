fn put64(out:&mut[u8],pos:&mut usize,x:i64){out[*pos..*pos+8].copy_from_slice(&x.to_le_bytes());*pos+=8;}
#[no_mangle]pub unsafe extern "C" fn stack_tracking_min_max(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2||length>130{return -1;}let max_size=*input;let op_count=*input.add(1);if !(0..=64).contains(&max_size)||!(0..=64).contains(&op_count){return -1;}let mut p=2usize;
 for _ in 0..op_count{if p>=length{return -1;}let op=*input.add(p);p+=1;if op==1{if p>=length{return -1;}let x=*input.add(p);if x<i32::MIN as i64||x>i32::MAX as i64{return -1;}p+=1;}else if !(2..=5).contains(&op){return -1;}}if p!=length{return -1;}
 let mut vals=[0i64;64];let mut mins=[0i64;64];let mut maxs=[0i64;64];let mut records=[[0i64;3];64];let(mut top,mut rc)=(0usize,0usize);p=2;
 for _ in 0..op_count{let op=*input.add(p);p+=1;let(mut tag,mut result)=(0i64,0i64);if op==1{let x=*input.add(p);p+=1;if top==max_size as usize{records[rc]=[1,4,1];rc+=1;break;}vals[top]=x;mins[top]=if top==0{x}else{mins[top-1].min(x)};maxs[top]=if top==0{x}else{maxs[top-1].max(x)};top+=1;tag=1;result=1;}else if op==2{if top>0{top-=1;result=vals[top];}else{tag=3;}}else if op==3{if top>0{result=mins[top-1];}else{tag=3;}}else if op==4{if top>0{result=maxs[top-1];}else{tag=3;}}else{tag=1;result=if top>0{1}else{0};}records[rc]=[op,tag,result];rc+=1;}
 let need=rc*24;if output.is_null()||capacity<need{return -2;}let out=std::slice::from_raw_parts_mut(output,need);let mut pos=0;for row in &records[..rc]{for x in row{put64(out,&mut pos,*x);}}pos as i64
}

#[no_mangle]
pub unsafe extern "C" fn one_dimensional(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n!=1{return -1}let code=*v;if !(0..=11_111_111).contains(&code){return -1}let mut digits=[0u8;8];let mut x=code as u64;let mut count=0;loop{let d=(x%10) as u8;if d>1{return -1}digits[count]=d;count+=1;x/=10;if x==0||count==8{break}}if x!=0{return -1}let mut rules=[0u8;8];for i in 0..count{rules[8-count+i]=digits[count-1-i]}
 let mut cells=[[0u8;31];17];cells[0][15]=1;for r in 0..16{for c in 0..31{let l=if c>0{cells[r][c-1] as usize}else{0};let m=cells[r][c] as usize;let right=if c+1<31{cells[r][c+1] as usize}else{0};cells[r+1][c]=rules[7-((l<<2)|(m<<1)|right)];}}
 let needed=17*31*3;if needed>cap||out.is_null(){return -2}let mut pos=0;for row in cells{for cell in row{let color=if cell==1{0}else{255};*out.add(pos)=color;*out.add(pos+1)=color;*out.add(pos+2)=color;pos+=3}}pos as i64
}

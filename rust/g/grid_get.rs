const MAX_COLUMNS:i64=1000;const MAX_INDEX:i64=10000;
#[no_mangle]
pub unsafe extern "C" fn grid_get(values:*const i64,length:usize)->i64{
 if values.is_null()||length<3||length>4{return -1;}
 let op=*values;let columns=*values.add(1);let index=*values.add(2);
 if (op!=0&&op!=1)||columns<1||columns>MAX_COLUMNS||index<0||index>MAX_INDEX{return -1;}
 if op==0{
  let mut remaining=index;
  while remaining+1>columns{remaining-=columns;}
  remaining+1
 }else{index/columns+1}
}

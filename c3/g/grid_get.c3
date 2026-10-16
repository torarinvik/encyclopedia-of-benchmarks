module grid_get;
const long MAX_COLUMNS=1000;const long MAX_INDEX=10000;
fn long grid_get_impl(long* values,usz length){
 if(values==null||length<3||length>4)return -1;
 long op=values[0],columns=values[1],index=values[2];
 if((op!=0&&op!=1)||columns<1||columns>MAX_COLUMNS||index<0||index>MAX_INDEX)return -1;
 if(op==0){
  long remaining=index;
  while(remaining+1>columns){remaining-=columns;}
  return remaining+1;
 }
 return index/columns+1;
}
fn long grid_get(long* values,usz length) @export("grid_get"){return grid_get_impl(values,length);}

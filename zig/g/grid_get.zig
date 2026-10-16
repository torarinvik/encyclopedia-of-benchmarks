export fn grid_get(values:[*c]const i64,length:usize)i64{
 if(values==null or length<3 or length>4)return -1;
 const operation=values[0];const columns=values[1];const index=values[2];
 if((operation!=0 and operation!=1) or columns<1 or columns>1000 or index<0 or index>10000)return -1;
 if(operation==0){
  var remaining=index;
  while(remaining+1>columns){remaining-=columns;}
  return remaining+1;
 }
 return @divTrunc(index,columns)+1;
}

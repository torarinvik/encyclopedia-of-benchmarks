package grid_get
import "core:c"
@(export)
grid_get::proc "c"(values:[^]i64,length:c.size_t)->i64{
 if values==nil||length<3||length>4 do return -1
 op,columns,index:=values[0],values[1],values[2]
 if (op!=0&&op!=1)||columns<1||columns>1000||index<0||index>10000 do return -1
 if op==0{
  remaining:=index
  for remaining+1>columns {remaining-=columns}
  return remaining+1
 }
 return index/columns+1
}

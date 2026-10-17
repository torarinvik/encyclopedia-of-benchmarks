module table_heap;

const usz MAX_ITEMS = 64;
const usz MAX_OPS = 256;
const usz MAP_CAPACITY = 128;
const long NIL_VALUE = -9223372036854775807 - 1;

struct MapEntry { int id; int priority; usz index; int state; }

usz map_hash(int id) { uint bits=@bitcast(uint,id);return (usz)((bits*2654435761u)&127u); }
usz map_find(MapEntry* map,int id){usz slot=map_hash(id);for(usz n=0;n<MAP_CAPACITY;n++){if(map[slot].state==0)return MAP_CAPACITY;if(map[slot].state==1&&map[slot].id==id)return slot;slot=(slot+1)&127;}return MAP_CAPACITY;}
usz map_insert(MapEntry* map,int id,int priority,usz index){usz slot=map_hash(id),tomb=MAP_CAPACITY;for(usz n=0;n<MAP_CAPACITY;n++){if(map[slot].state==2&&tomb==MAP_CAPACITY)tomb=slot;if(map[slot].state==0){if(tomb!=MAP_CAPACITY)slot=tomb;map[slot]=MapEntry{id,priority,index,1};return slot;}if(map[slot].state==1&&map[slot].id==id)return slot;slot=(slot+1)&127;}if(tomb!=MAP_CAPACITY){map[tomb]=MapEntry{id,priority,index,1};return tomb;}return MAP_CAPACITY;}
void map_remove(MapEntry* map,usz slot){map[slot].state=2;}
int priority_of(MapEntry* map,int id){return map[map_find(map,id)].priority;}
void swap_ids(int* heap,MapEntry* map,usz a,usz b,bool update){int x=heap[a];heap[a]=heap[b];heap[b]=x;if(update){map[map_find(map,heap[a])].index=a;map[map_find(map,heap[b])].index=b;}}
void down(int* heap,usz count,MapEntry* map,usz index,bool update){while(true){usz left=index*2+1;if(left>=count)return;usz child=left+1;if(child>=count||priority_of(map,heap[left])<priority_of(map,heap[child]))child=left;if(priority_of(map,heap[child])>=priority_of(map,heap[index]))return;swap_ids(heap,map,index,child,update);index=child;}}
void up(int* heap,MapEntry* map,usz index){while(index>0){usz parent=(index-1)/2;if(priority_of(map,heap[index])>=priority_of(map,heap[parent]))return;swap_ids(heap,map,index,parent,true);index=parent;}}
void store_i64(char* output,usz offset,long value){ulong bits=@bitcast(ulong,value);for(usz b=0;b<8;b++)output[offset+b]=(char)(bits>>(8*b));}

fn long table_heap(long* input,usz length,char* output,usz capacity) @export("table_heap") {
    if(input==null||length<2||length>1155)return -1;if(input[0]<0||input[0]>64)return -1;usz initial=(usz)input[0],op_index=1+2*initial;
    if(length<=op_index||input[op_index]<0||input[op_index]>256)return -1;usz op_count=(usz)input[op_index];if(length!=2+2*initial+4*op_count||length>1154)return -1;
    int[MAX_ITEMS] heap=zeroed;MapEntry[MAP_CAPACITY] map=zeroed;usz count=initial;
    for(usz i=0;i<initial;i++){long id=input[1+2*i],p=input[2+2*i];if(id< -2147483648||id>2147483647||p< -2147483648||p>2147483647)return -1;int item=(int)id;if(map_find(&map[0],item)!=MAP_CAPACITY)return -1;heap[i]=item;if(map_insert(&map[0],item,(int)p,0)==MAP_CAPACITY)return -1;}
    usz parent=count/2;while(parent>0){parent--;down(&heap[0],count,&map[0],parent,false);}for(usz i=0;i<count;i++)map[map_find(&map[0],heap[i])].index=i;
    long[MAX_OPS] answers=zeroed;usz cursor=op_index+1;
    for(usz oi=0;oi<op_count;oi++){long op=input[cursor],a=input[cursor+1],b=input[cursor+2],c=input[cursor+3];cursor+=4;if(op<0||op>9)return -1;
        if(op==0){if(a< -2147483648||a>2147483647||b< -2147483648||b>2147483647||c!=0||count==MAX_ITEMS||map_find(&map[0],(int)a)!=MAP_CAPACITY)return -1;heap[count]=(int)a;if(map_insert(&map[0],(int)a,(int)b,count)==MAP_CAPACITY)return -1;count++;up(&heap[0],&map[0],count-1);answers[oi]=NIL_VALUE;
        }else if(op==1){if(a!=0||b!=0||c!=0)return -1;answers[oi]=count==0?NIL_VALUE:(long)heap[0];
        }else if(op==2){if(a!=0||b!=0||c!=0||count==0)return -1;int removed=heap[0];usz old=map_find(&map[0],removed);answers[oi]=(long)removed;swap_ids(&heap[0],&map[0],0,count-1,true);count--;map_remove(&map[0],old);if(count>0)down(&heap[0],count,&map[0],0,true);
        }else if(op==3||op==4){if(a!=0||b!=0||c!=0)return -1;answers[oi]=op==3?(long)count:(count==0?1:0);
        }else if(op==5){if(a< -2147483648||a>2147483647||b!=0||c!=0)return -1;usz slot=map_find(&map[0],(int)a);answers[oi]=slot==MAP_CAPACITY?NIL_VALUE:(long)map[slot].index+1;
        }else if(op==6||op==7){if(a< -2147483648||a>2147483647||b< -2147483648||b>2147483647||c!=0)return -1;usz slot=map_find(&map[0],(int)a);if(slot==MAP_CAPACITY||(op==6&&b>map[slot].priority)||(op==7&&b<map[slot].priority))return -1;map[slot].priority=(int)b;if(op==6)up(&heap[0],&map[0],map[slot].index);else down(&heap[0],count,&map[0],map[slot].index,true);answers[oi]=NIL_VALUE;
        }else if(op==8){if(a< -2147483648||a>2147483647||b< -2147483648||b>2147483647||c< -2147483648||c>2147483647)return -1;usz old=map_find(&map[0],(int)a),newslot=map_find(&map[0],(int)b);if(old==MAP_CAPACITY||(newslot!=MAP_CAPACITY&&((int)b!=(int)a||c!=map[old].priority)))return -1;if(newslot==MAP_CAPACITY){usz pos=map[old].index;int oldp=map[old].priority;map_remove(&map[0],old);if(map_insert(&map[0],(int)b,(int)c,pos)==MAP_CAPACITY)return -1;heap[pos]=(int)b;if((int)c<oldp)up(&heap[0],&map[0],pos);else down(&heap[0],count,&map[0],pos,true);}answers[oi]=NIL_VALUE;
        }else{if(a< -2147483648||a>2147483647||b!=0||c!=0)return -1;usz slot=map_find(&map[0],(int)a);if(slot==MAP_CAPACITY)return -1;usz pos=map[slot].index;int oldp=map[slot].priority;count--;if(pos!=count){heap[pos]=heap[count];map[map_find(&map[0],heap[pos])].index=pos;if(priority_of(&map[0],heap[pos])<oldp)up(&heap[0],&map[0],pos);else down(&heap[0],count,&map[0],pos,true);}map_remove(&map[0],slot);answers[oi]=NIL_VALUE;}
    }
    usz bytes=op_count*8;if(output==null||capacity<bytes)return -2;for(usz i=0;i<op_count;i++)store_i64(output,8*i,answers[i]);return (long)bytes;
}

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List

fn des_table_ip()->List[Int]:
    var t=List[Int](capacity=64)
    t.append(58);t.append(50);t.append(42);t.append(34);t.append(26);t.append(18);t.append(10);t.append(2);t.append(60);t.append(52);t.append(44);t.append(36);t.append(28);t.append(20);t.append(12);t.append(4)
    t.append(62);t.append(54);t.append(46);t.append(38);t.append(30);t.append(22);t.append(14);t.append(6);t.append(64);t.append(56);t.append(48);t.append(40);t.append(32);t.append(24);t.append(16);t.append(8)
    t.append(57);t.append(49);t.append(41);t.append(33);t.append(25);t.append(17);t.append(9);t.append(1);t.append(59);t.append(51);t.append(43);t.append(35);t.append(27);t.append(19);t.append(11);t.append(3)
    t.append(61);t.append(53);t.append(45);t.append(37);t.append(29);t.append(21);t.append(13);t.append(5);t.append(63);t.append(55);t.append(47);t.append(39);t.append(31);t.append(23);t.append(15);t.append(7)
    return t

fn des_table_ip_inv()->List[Int]:
    var t=List[Int](capacity=64)
    t.append(40);t.append(8);t.append(48);t.append(16);t.append(56);t.append(24);t.append(64);t.append(32);t.append(39);t.append(7);t.append(47);t.append(15);t.append(55);t.append(23);t.append(63);t.append(31)
    t.append(38);t.append(6);t.append(46);t.append(14);t.append(54);t.append(22);t.append(62);t.append(30);t.append(37);t.append(5);t.append(45);t.append(13);t.append(53);t.append(21);t.append(61);t.append(29)
    t.append(36);t.append(4);t.append(44);t.append(12);t.append(52);t.append(20);t.append(60);t.append(28);t.append(35);t.append(3);t.append(43);t.append(11);t.append(51);t.append(19);t.append(59);t.append(27)
    t.append(34);t.append(2);t.append(42);t.append(10);t.append(50);t.append(18);t.append(58);t.append(26);t.append(33);t.append(1);t.append(41);t.append(9);t.append(49);t.append(17);t.append(57);t.append(25)
    return t

fn des_table_e()->List[Int]:
    var t=List[Int](capacity=48)
    t.append(32);t.append(1);t.append(2);t.append(3);t.append(4);t.append(5);t.append(4);t.append(5);t.append(6);t.append(7);t.append(8);t.append(9);t.append(8);t.append(9);t.append(10);t.append(11)
    t.append(12);t.append(13);t.append(12);t.append(13);t.append(14);t.append(15);t.append(16);t.append(17);t.append(16);t.append(17);t.append(18);t.append(19);t.append(20);t.append(21);t.append(20);t.append(21)
    t.append(22);t.append(23);t.append(24);t.append(25);t.append(24);t.append(25);t.append(26);t.append(27);t.append(28);t.append(29);t.append(28);t.append(29);t.append(30);t.append(31);t.append(32);t.append(1)
    return t

fn des_table_p()->List[Int]:
    var t=List[Int](capacity=32)
    t.append(16);t.append(7);t.append(20);t.append(21);t.append(29);t.append(12);t.append(28);t.append(17);t.append(1);t.append(15);t.append(23);t.append(26);t.append(5);t.append(18);t.append(31);t.append(10)
    t.append(2);t.append(8);t.append(24);t.append(14);t.append(32);t.append(27);t.append(3);t.append(9);t.append(19);t.append(13);t.append(30);t.append(6);t.append(22);t.append(11);t.append(4);t.append(25)
    return t

fn des_table_pc1()->List[Int]:
    var t=List[Int](capacity=56)
    t.append(57);t.append(49);t.append(41);t.append(33);t.append(25);t.append(17);t.append(9);t.append(1);t.append(58);t.append(50);t.append(42);t.append(34);t.append(26);t.append(18);t.append(10);t.append(2)
    t.append(59);t.append(51);t.append(43);t.append(35);t.append(27);t.append(19);t.append(11);t.append(3);t.append(60);t.append(52);t.append(44);t.append(36);t.append(63);t.append(55);t.append(47);t.append(39)
    t.append(31);t.append(23);t.append(15);t.append(7);t.append(62);t.append(54);t.append(46);t.append(38);t.append(30);t.append(22);t.append(14);t.append(6);t.append(61);t.append(53);t.append(45);t.append(37)
    t.append(29);t.append(21);t.append(13);t.append(5);t.append(28);t.append(20);t.append(12);t.append(4)
    return t

fn des_table_pc2()->List[Int]:
    var t=List[Int](capacity=48)
    t.append(14);t.append(17);t.append(11);t.append(24);t.append(1);t.append(5);t.append(3);t.append(28);t.append(15);t.append(6);t.append(21);t.append(10);t.append(23);t.append(19);t.append(12);t.append(4)
    t.append(26);t.append(8);t.append(16);t.append(7);t.append(27);t.append(20);t.append(13);t.append(2);t.append(41);t.append(52);t.append(31);t.append(37);t.append(47);t.append(55);t.append(30);t.append(40)
    t.append(51);t.append(45);t.append(33);t.append(48);t.append(44);t.append(49);t.append(39);t.append(56);t.append(34);t.append(53);t.append(46);t.append(42);t.append(50);t.append(36);t.append(29);t.append(32)
    return t

fn des_table_shifts()->List[Int]:
    var t=List[Int](capacity=16)
    t.append(1);t.append(1);t.append(2);t.append(2);t.append(2);t.append(2);t.append(2);t.append(2);t.append(1);t.append(2);t.append(2);t.append(2);t.append(2);t.append(2);t.append(2);t.append(1)
    return t

fn des_table_sbox()->List[Int]:
    var t=List[Int](capacity=512)
    t.append(14);t.append(4);t.append(13);t.append(1);t.append(2);t.append(15);t.append(11);t.append(8);t.append(3);t.append(10);t.append(6);t.append(12);t.append(5);t.append(9);t.append(0);t.append(7)
    t.append(0);t.append(15);t.append(7);t.append(4);t.append(14);t.append(2);t.append(13);t.append(1);t.append(10);t.append(6);t.append(12);t.append(11);t.append(9);t.append(5);t.append(3);t.append(8)
    t.append(4);t.append(1);t.append(14);t.append(8);t.append(13);t.append(6);t.append(2);t.append(11);t.append(15);t.append(12);t.append(9);t.append(7);t.append(3);t.append(10);t.append(5);t.append(0)
    t.append(15);t.append(12);t.append(8);t.append(2);t.append(4);t.append(9);t.append(1);t.append(7);t.append(5);t.append(11);t.append(3);t.append(14);t.append(10);t.append(0);t.append(6);t.append(13)
    t.append(15);t.append(1);t.append(8);t.append(14);t.append(6);t.append(11);t.append(3);t.append(4);t.append(9);t.append(7);t.append(2);t.append(13);t.append(12);t.append(0);t.append(5);t.append(10)
    t.append(3);t.append(13);t.append(4);t.append(7);t.append(15);t.append(2);t.append(8);t.append(14);t.append(12);t.append(0);t.append(1);t.append(10);t.append(6);t.append(9);t.append(11);t.append(5)
    t.append(0);t.append(14);t.append(7);t.append(11);t.append(10);t.append(4);t.append(13);t.append(1);t.append(5);t.append(8);t.append(12);t.append(6);t.append(9);t.append(3);t.append(2);t.append(15)
    t.append(13);t.append(8);t.append(10);t.append(1);t.append(3);t.append(15);t.append(4);t.append(2);t.append(11);t.append(6);t.append(7);t.append(12);t.append(0);t.append(5);t.append(14);t.append(9)
    t.append(10);t.append(0);t.append(9);t.append(14);t.append(6);t.append(3);t.append(15);t.append(5);t.append(1);t.append(13);t.append(12);t.append(7);t.append(11);t.append(4);t.append(2);t.append(8)
    t.append(13);t.append(7);t.append(0);t.append(9);t.append(3);t.append(4);t.append(6);t.append(10);t.append(2);t.append(8);t.append(5);t.append(14);t.append(12);t.append(11);t.append(15);t.append(1)
    t.append(13);t.append(6);t.append(4);t.append(9);t.append(8);t.append(15);t.append(3);t.append(0);t.append(11);t.append(1);t.append(2);t.append(12);t.append(5);t.append(10);t.append(14);t.append(7)
    t.append(1);t.append(10);t.append(13);t.append(0);t.append(6);t.append(9);t.append(8);t.append(7);t.append(4);t.append(15);t.append(14);t.append(3);t.append(11);t.append(5);t.append(2);t.append(12)
    t.append(7);t.append(13);t.append(14);t.append(3);t.append(0);t.append(6);t.append(9);t.append(10);t.append(1);t.append(2);t.append(8);t.append(5);t.append(11);t.append(12);t.append(4);t.append(15)
    t.append(13);t.append(8);t.append(11);t.append(5);t.append(6);t.append(15);t.append(0);t.append(3);t.append(4);t.append(7);t.append(2);t.append(12);t.append(1);t.append(10);t.append(14);t.append(9)
    t.append(10);t.append(6);t.append(9);t.append(0);t.append(12);t.append(11);t.append(7);t.append(13);t.append(15);t.append(1);t.append(3);t.append(14);t.append(5);t.append(2);t.append(8);t.append(4)
    t.append(3);t.append(15);t.append(0);t.append(6);t.append(10);t.append(1);t.append(13);t.append(8);t.append(9);t.append(4);t.append(5);t.append(11);t.append(12);t.append(7);t.append(2);t.append(14)
    t.append(2);t.append(12);t.append(4);t.append(1);t.append(7);t.append(10);t.append(11);t.append(6);t.append(8);t.append(5);t.append(3);t.append(15);t.append(13);t.append(0);t.append(14);t.append(9)
    t.append(14);t.append(11);t.append(2);t.append(12);t.append(4);t.append(7);t.append(13);t.append(1);t.append(5);t.append(0);t.append(15);t.append(10);t.append(3);t.append(9);t.append(8);t.append(6)
    t.append(4);t.append(2);t.append(1);t.append(11);t.append(10);t.append(13);t.append(7);t.append(8);t.append(15);t.append(9);t.append(12);t.append(5);t.append(6);t.append(3);t.append(0);t.append(14)
    t.append(11);t.append(8);t.append(12);t.append(7);t.append(1);t.append(14);t.append(2);t.append(13);t.append(6);t.append(15);t.append(0);t.append(9);t.append(10);t.append(4);t.append(5);t.append(3)
    t.append(12);t.append(1);t.append(10);t.append(15);t.append(9);t.append(2);t.append(6);t.append(8);t.append(0);t.append(13);t.append(3);t.append(4);t.append(14);t.append(7);t.append(5);t.append(11)
    t.append(10);t.append(15);t.append(4);t.append(2);t.append(7);t.append(12);t.append(9);t.append(5);t.append(6);t.append(1);t.append(13);t.append(14);t.append(0);t.append(11);t.append(3);t.append(8)
    t.append(9);t.append(14);t.append(15);t.append(5);t.append(2);t.append(8);t.append(12);t.append(3);t.append(7);t.append(0);t.append(4);t.append(10);t.append(1);t.append(13);t.append(11);t.append(6)
    t.append(4);t.append(3);t.append(2);t.append(12);t.append(9);t.append(5);t.append(15);t.append(10);t.append(11);t.append(14);t.append(1);t.append(7);t.append(6);t.append(0);t.append(8);t.append(13)
    t.append(4);t.append(11);t.append(2);t.append(14);t.append(15);t.append(0);t.append(8);t.append(13);t.append(3);t.append(12);t.append(9);t.append(7);t.append(5);t.append(10);t.append(6);t.append(1)
    t.append(13);t.append(0);t.append(11);t.append(7);t.append(4);t.append(9);t.append(1);t.append(10);t.append(14);t.append(3);t.append(5);t.append(12);t.append(2);t.append(15);t.append(8);t.append(6)
    t.append(1);t.append(4);t.append(11);t.append(13);t.append(12);t.append(3);t.append(7);t.append(14);t.append(10);t.append(15);t.append(6);t.append(8);t.append(0);t.append(5);t.append(9);t.append(2)
    t.append(6);t.append(11);t.append(13);t.append(8);t.append(1);t.append(4);t.append(10);t.append(7);t.append(9);t.append(5);t.append(0);t.append(15);t.append(14);t.append(2);t.append(3);t.append(12)
    t.append(13);t.append(2);t.append(8);t.append(4);t.append(6);t.append(15);t.append(11);t.append(1);t.append(10);t.append(9);t.append(3);t.append(14);t.append(5);t.append(0);t.append(12);t.append(7)
    t.append(1);t.append(15);t.append(13);t.append(8);t.append(10);t.append(3);t.append(7);t.append(4);t.append(12);t.append(5);t.append(6);t.append(11);t.append(0);t.append(14);t.append(9);t.append(2)
    t.append(7);t.append(11);t.append(4);t.append(1);t.append(9);t.append(12);t.append(14);t.append(2);t.append(0);t.append(6);t.append(10);t.append(13);t.append(15);t.append(3);t.append(5);t.append(8)
    t.append(2);t.append(1);t.append(14);t.append(7);t.append(4);t.append(10);t.append(8);t.append(13);t.append(15);t.append(12);t.append(9);t.append(0);t.append(3);t.append(5);t.append(6);t.append(11)
    return t

fn des_perm(value:UInt64,table:List[Int],width:Int)->UInt64:
    var result:UInt64=0
    for i in range(len(table)):result=(result<<1)|((value>>UInt(width-table[i]))&1)
    return result
fn des_make_keys(key:UInt64,pc1:List[Int],pc2:List[Int],shifts:List[Int])->List[UInt64]:
    let selected=des_perm(key,pc1,64);let mask=(UInt64(1)<<28)-1
    var c=UInt32(selected>>28);var d=UInt32(selected&mask);var keys=List[UInt64](capacity=16)
    for i in range(16):
        let s=shifts[i];c=((c<<UInt(s))|(c>>UInt(28-s)))&UInt32(mask);d=((d<<UInt(s))|(d>>UInt(28-s)))&UInt32(mask)
        keys.append(des_perm((UInt64(c)<<28)|UInt64(d),pc2,56))
    return keys
fn des_feistel(right:UInt32,key:UInt64,e:List[Int],p:List[Int],sbox:List[Int])->UInt32:
    let expanded=des_perm(UInt64(right),e,32)^key;var joined:UInt32=0
    for i in range(8):
        let six=Int((expanded>>UInt(42-6*i))&63);let row=((six&32)>>4)|(six&1);let col=(six>>1)&15
        joined=(joined<<4)|UInt32(sbox[i*64+row*16+col])
    return UInt32(des_perm(UInt64(joined),p,32))
fn des_encrypt(block:UInt64,keys:List[UInt64],ip:List[Int],inv:List[Int],e:List[Int],p:List[Int],sbox:List[Int])->UInt64:
    let permuted=des_perm(block,ip,64);var left=UInt32(permuted>>32);var right=UInt32(permuted)
    for i in range(16):let next=left^des_feistel(right,keys[i],e,p,sbox);left=right;right=next
    return des_perm((UInt64(right)<<32)|UInt64(left),inv,64)
@export("des_ecb")
fn des_ecb(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>42:return -1
    let nv=input[0]
    if nv<0 or nv>40 or length!=c_size_t(nv+2):return -1
    let n=Int(nv)
    for i in range(n):if input[2+i]<0 or input[2+i]>127:return -1
    let blocks=(n+7)/8;let outn=blocks*8
    if outn==0:return 0
    let ip=des_table_ip();let inv=des_table_ip_inv();let e=des_table_e();let p=des_table_p();let pc1=des_table_pc1();let pc2=des_table_pc2();let shifts=des_table_shifts();let sbox=des_table_sbox()
    let keys=des_make_keys(bitcast[UInt64](input[1]),pc1,pc2,shifts);var staged=List[UInt8](length=outn,fill=0)
    for block_index in range(blocks):
        var block:UInt64=0
        for j in range(8):
            let k=block_index*8+j;var byte:UInt64=0
            if k<n:byte=UInt64(input[2+k])
            block=(block<<8)|byte
        let encrypted=des_encrypt(block,keys,ip,inv,e,p,sbox)
        for j in range(8):staged[block_index*8+j]=UInt8((encrypted>>UInt(56-8*j))&255)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(outn):return -2
    for i in range(outn):out[i]=staged[i]
    return Int64(outn)

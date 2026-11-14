# Independently written tripforce kernel; GPL-3.0, see package LICENSE.
# DES tables and helpers originate in the local des_ecb draft.
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
fn des_transform(block:UInt64,keys:List[UInt64],decrypt:Bool,ip:List[Int],inv:List[Int],e:List[Int],p:List[Int],sbox:List[Int])->UInt64:
    let permuted=des_perm(block,ip,64);var left=UInt32(permuted>>32);var right=UInt32(permuted & UInt64(0xffffffff))
    for i in range(16):
        var key_index = i
        if decrypt: key_index = 15-i
        let next=left^des_feistel(right,keys[key_index],e,p,sbox)
        left=right;right=next
    return des_perm((UInt64(right)<<32)|UInt64(left),inv,64)

fn trip_salt_value(original:Int) -> Int:
    var c=original
    if c<46 or c>122:c=46
    if (c>=58 and c<=64) or (c>=91 and c<=96):c+=6
    if c==64:return 11
    if c<=57:return c-46
    if c<=90:return c-53
    return c-59

fn trip_alphabet(index:Int) -> UInt8:
    if index==0:return 46
    if index==1:return 47
    if index<12:return UInt8(index+46)
    if index<38:return UInt8(index+53)
    return UInt8(index+59)

@export("tripforce_tripcode")
fn tripforce_tripcode(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=8:return -1
    var key:UInt64=0
    for i in range(8):
        let c=input[i]
        if c<32 or c>125 or c==35 or c==92:return -1
        key=(key<<8)|UInt64((c<<1)&255)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<10:return -2
    let salt=trip_salt_value(Int(input[1])) | (trip_salt_value(Int(input[2]))<<6)
    let ip=des_table_ip();let inv=des_table_ip_inv();var expansion=des_table_e();let p=des_table_p()
    for i in range(12):
        if ((salt>>i)&1)!=0:
            let tmp=expansion[i]
            expansion[i]=expansion[i+24]
            expansion[i+24]=tmp
    let keys=des_make_keys(key,des_table_pc1(),des_table_pc2(),des_table_shifts())
    let sbox=des_table_sbox()
    var block:UInt64=0
    for _ in range(25):block=des_transform(block,keys,False,ip,inv,expansion,p,sbox)
    # Serialize each 32-bit word least-significant byte first, then encode
    # bits most-significant first; skip the first encoded character.
    var bytes=List[UInt8](length=8,fill=0)
    for i in range(8):
        var shift=8*(i%4)
        if i<4:shift+=32
        bytes[i]=UInt8((block>>UInt(shift))&255)
    for i in range(10):
        var value=0
        for j in range(6):
            let bit=(i+1)*6+j
            value=value<<1
            if bit<64:value|=Int((bytes[bit//8]>>UInt(7-bit%8))&1)
        out[i]=trip_alphabet(value)
    return 10


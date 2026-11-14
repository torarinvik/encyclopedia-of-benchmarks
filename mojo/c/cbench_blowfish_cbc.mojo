# crypto/bf/bf_enc.c
# Copyright (C) 1995-1997 Eric Young (eay@mincom.oz.au)
# All rights reserved.
# 
# This package is an SSL implementation written
# by Eric Young (eay@mincom.oz.au).
# The implementation was written so as to conform with Netscapes SSL.
# 
# This library is free for commercial and non-commercial use as long as
# the following conditions are aheared to.  The following conditions
# apply to all code found in this distribution, be it the RC4, RSA,
# lhash, DES, etc., code; not just the SSL code.  The SSL documentation
# included with this distribution is covered by the same copyright terms
# except that the holder is Tim Hudson (tjh@mincom.oz.au).
# 
# Copyright remains Eric Young's, and as such any Copyright notices in
# the code are not to be removed.
# If this package is used in a product, Eric Young should be given attribution
# as the author of the parts of the library used.
# This can be in the form of a textual message at program startup or
# in documentation (online or textual) provided with the package.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
# must display the following acknowledgement:
# "This product includes cryptographic software written by
# Eric Young (eay@mincom.oz.au)"
# The word 'cryptographic' can be left out if the rouines from the library
# being used are not cryptographic related :-).
# 4. If you include any Windows specific code (or a derivative thereof) from 
# the apps directory (application code) you must include an acknowledgement:
# "This product includes software written by Tim Hudson (tjh@mincom.oz.au)"
# 
# THIS SOFTWARE IS PROVIDED BY ERIC YOUNG ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
# 
# The licence and distribution terms for any publically available version or
# derivative of this code cannot be changed.  i.e. this code cannot simply be
# copied and put under another distribution licence
# [including the GNU Public Licence.]
# 
from std.ffi import c_size_t
from std.collections import List
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn blowfish_initial_words() -> List[UInt32]:
    var t=List[UInt32](capacity=1042)
    t.append(0x243f6a88); t.append(0x85a308d3); t.append(0x13198a2e); t.append(0x03707344); t.append(0xa4093822); t.append(0x299f31d0);
    t.append(0x082efa98); t.append(0xec4e6c89); t.append(0x452821e6); t.append(0x38d01377); t.append(0xbe5466cf); t.append(0x34e90c6c);
    t.append(0xc0ac29b7); t.append(0xc97c50dd); t.append(0x3f84d5b5); t.append(0xb5470917); t.append(0x9216d5d9); t.append(0x8979fb1b);
    t.append(0xd1310ba6); t.append(0x98dfb5ac); t.append(0x2ffd72db); t.append(0xd01adfb7); t.append(0xb8e1afed); t.append(0x6a267e96);
    t.append(0xba7c9045); t.append(0xf12c7f99); t.append(0x24a19947); t.append(0xb3916cf7); t.append(0x0801f2e2); t.append(0x858efc16);
    t.append(0x636920d8); t.append(0x71574e69); t.append(0xa458fea3); t.append(0xf4933d7e); t.append(0x0d95748f); t.append(0x728eb658);
    t.append(0x718bcd58); t.append(0x82154aee); t.append(0x7b54a41d); t.append(0xc25a59b5); t.append(0x9c30d539); t.append(0x2af26013);
    t.append(0xc5d1b023); t.append(0x286085f0); t.append(0xca417918); t.append(0xb8db38ef); t.append(0x8e79dcb0); t.append(0x603a180e);
    t.append(0x6c9e0e8b); t.append(0xb01e8a3e); t.append(0xd71577c1); t.append(0xbd314b27); t.append(0x78af2fda); t.append(0x55605c60);
    t.append(0xe65525f3); t.append(0xaa55ab94); t.append(0x57489862); t.append(0x63e81440); t.append(0x55ca396a); t.append(0x2aab10b6);
    t.append(0xb4cc5c34); t.append(0x1141e8ce); t.append(0xa15486af); t.append(0x7c72e993); t.append(0xb3ee1411); t.append(0x636fbc2a);
    t.append(0x2ba9c55d); t.append(0x741831f6); t.append(0xce5c3e16); t.append(0x9b87931e); t.append(0xafd6ba33); t.append(0x6c24cf5c);
    t.append(0x7a325381); t.append(0x28958677); t.append(0x3b8f4898); t.append(0x6b4bb9af); t.append(0xc4bfe81b); t.append(0x66282193);
    t.append(0x61d809cc); t.append(0xfb21a991); t.append(0x487cac60); t.append(0x5dec8032); t.append(0xef845d5d); t.append(0xe98575b1);
    t.append(0xdc262302); t.append(0xeb651b88); t.append(0x23893e81); t.append(0xd396acc5); t.append(0x0f6d6ff3); t.append(0x83f44239);
    t.append(0x2e0b4482); t.append(0xa4842004); t.append(0x69c8f04a); t.append(0x9e1f9b5e); t.append(0x21c66842); t.append(0xf6e96c9a);
    t.append(0x670c9c61); t.append(0xabd388f0); t.append(0x6a51a0d2); t.append(0xd8542f68); t.append(0x960fa728); t.append(0xab5133a3);
    t.append(0x6eef0b6c); t.append(0x137a3be4); t.append(0xba3bf050); t.append(0x7efb2a98); t.append(0xa1f1651d); t.append(0x39af0176);
    t.append(0x66ca593e); t.append(0x82430e88); t.append(0x8cee8619); t.append(0x456f9fb4); t.append(0x7d84a5c3); t.append(0x3b8b5ebe);
    t.append(0xe06f75d8); t.append(0x85c12073); t.append(0x401a449f); t.append(0x56c16aa6); t.append(0x4ed3aa62); t.append(0x363f7706);
    t.append(0x1bfedf72); t.append(0x429b023d); t.append(0x37d0d724); t.append(0xd00a1248); t.append(0xdb0fead3); t.append(0x49f1c09b);
    t.append(0x075372c9); t.append(0x80991b7b); t.append(0x25d479d8); t.append(0xf6e8def7); t.append(0xe3fe501a); t.append(0xb6794c3b);
    t.append(0x976ce0bd); t.append(0x04c006ba); t.append(0xc1a94fb6); t.append(0x409f60c4); t.append(0x5e5c9ec2); t.append(0x196a2463);
    t.append(0x68fb6faf); t.append(0x3e6c53b5); t.append(0x1339b2eb); t.append(0x3b52ec6f); t.append(0x6dfc511f); t.append(0x9b30952c);
    t.append(0xcc814544); t.append(0xaf5ebd09); t.append(0xbee3d004); t.append(0xde334afd); t.append(0x660f2807); t.append(0x192e4bb3);
    t.append(0xc0cba857); t.append(0x45c8740f); t.append(0xd20b5f39); t.append(0xb9d3fbdb); t.append(0x5579c0bd); t.append(0x1a60320a);
    t.append(0xd6a100c6); t.append(0x402c7279); t.append(0x679f25fe); t.append(0xfb1fa3cc); t.append(0x8ea5e9f8); t.append(0xdb3222f8);
    t.append(0x3c7516df); t.append(0xfd616b15); t.append(0x2f501ec8); t.append(0xad0552ab); t.append(0x323db5fa); t.append(0xfd238760);
    t.append(0x53317b48); t.append(0x3e00df82); t.append(0x9e5c57bb); t.append(0xca6f8ca0); t.append(0x1a87562e); t.append(0xdf1769db);
    t.append(0xd542a8f6); t.append(0x287effc3); t.append(0xac6732c6); t.append(0x8c4f5573); t.append(0x695b27b0); t.append(0xbbca58c8);
    t.append(0xe1ffa35d); t.append(0xb8f011a0); t.append(0x10fa3d98); t.append(0xfd2183b8); t.append(0x4afcb56c); t.append(0x2dd1d35b);
    t.append(0x9a53e479); t.append(0xb6f84565); t.append(0xd28e49bc); t.append(0x4bfb9790); t.append(0xe1ddf2da); t.append(0xa4cb7e33);
    t.append(0x62fb1341); t.append(0xcee4c6e8); t.append(0xef20cada); t.append(0x36774c01); t.append(0xd07e9efe); t.append(0x2bf11fb4);
    t.append(0x95dbda4d); t.append(0xae909198); t.append(0xeaad8e71); t.append(0x6b93d5a0); t.append(0xd08ed1d0); t.append(0xafc725e0);
    t.append(0x8e3c5b2f); t.append(0x8e7594b7); t.append(0x8ff6e2fb); t.append(0xf2122b64); t.append(0x8888b812); t.append(0x900df01c);
    t.append(0x4fad5ea0); t.append(0x688fc31c); t.append(0xd1cff191); t.append(0xb3a8c1ad); t.append(0x2f2f2218); t.append(0xbe0e1777);
    t.append(0xea752dfe); t.append(0x8b021fa1); t.append(0xe5a0cc0f); t.append(0xb56f74e8); t.append(0x18acf3d6); t.append(0xce89e299);
    t.append(0xb4a84fe0); t.append(0xfd13e0b7); t.append(0x7cc43b81); t.append(0xd2ada8d9); t.append(0x165fa266); t.append(0x80957705);
    t.append(0x93cc7314); t.append(0x211a1477); t.append(0xe6ad2065); t.append(0x77b5fa86); t.append(0xc75442f5); t.append(0xfb9d35cf);
    t.append(0xebcdaf0c); t.append(0x7b3e89a0); t.append(0xd6411bd3); t.append(0xae1e7e49); t.append(0x00250e2d); t.append(0x2071b35e);
    t.append(0x226800bb); t.append(0x57b8e0af); t.append(0x2464369b); t.append(0xf009b91e); t.append(0x5563911d); t.append(0x59dfa6aa);
    t.append(0x78c14389); t.append(0xd95a537f); t.append(0x207d5ba2); t.append(0x02e5b9c5); t.append(0x83260376); t.append(0x6295cfa9);
    t.append(0x11c81968); t.append(0x4e734a41); t.append(0xb3472dca); t.append(0x7b14a94a); t.append(0x1b510052); t.append(0x9a532915);
    t.append(0xd60f573f); t.append(0xbc9bc6e4); t.append(0x2b60a476); t.append(0x81e67400); t.append(0x08ba6fb5); t.append(0x571be91f);
    t.append(0xf296ec6b); t.append(0x2a0dd915); t.append(0xb6636521); t.append(0xe7b9f9b6); t.append(0xff34052e); t.append(0xc5855664);
    t.append(0x53b02d5d); t.append(0xa99f8fa1); t.append(0x08ba4799); t.append(0x6e85076a); t.append(0x4b7a70e9); t.append(0xb5b32944);
    t.append(0xdb75092e); t.append(0xc4192623); t.append(0xad6ea6b0); t.append(0x49a7df7d); t.append(0x9cee60b8); t.append(0x8fedb266);
    t.append(0xecaa8c71); t.append(0x699a17ff); t.append(0x5664526c); t.append(0xc2b19ee1); t.append(0x193602a5); t.append(0x75094c29);
    t.append(0xa0591340); t.append(0xe4183a3e); t.append(0x3f54989a); t.append(0x5b429d65); t.append(0x6b8fe4d6); t.append(0x99f73fd6);
    t.append(0xa1d29c07); t.append(0xefe830f5); t.append(0x4d2d38e6); t.append(0xf0255dc1); t.append(0x4cdd2086); t.append(0x8470eb26);
    t.append(0x6382e9c6); t.append(0x021ecc5e); t.append(0x09686b3f); t.append(0x3ebaefc9); t.append(0x3c971814); t.append(0x6b6a70a1);
    t.append(0x687f3584); t.append(0x52a0e286); t.append(0xb79c5305); t.append(0xaa500737); t.append(0x3e07841c); t.append(0x7fdeae5c);
    t.append(0x8e7d44ec); t.append(0x5716f2b8); t.append(0xb03ada37); t.append(0xf0500c0d); t.append(0xf01c1f04); t.append(0x0200b3ff);
    t.append(0xae0cf51a); t.append(0x3cb574b2); t.append(0x25837a58); t.append(0xdc0921bd); t.append(0xd19113f9); t.append(0x7ca92ff6);
    t.append(0x94324773); t.append(0x22f54701); t.append(0x3ae5e581); t.append(0x37c2dadc); t.append(0xc8b57634); t.append(0x9af3dda7);
    t.append(0xa9446146); t.append(0x0fd0030e); t.append(0xecc8c73e); t.append(0xa4751e41); t.append(0xe238cd99); t.append(0x3bea0e2f);
    t.append(0x3280bba1); t.append(0x183eb331); t.append(0x4e548b38); t.append(0x4f6db908); t.append(0x6f420d03); t.append(0xf60a04bf);
    t.append(0x2cb81290); t.append(0x24977c79); t.append(0x5679b072); t.append(0xbcaf89af); t.append(0xde9a771f); t.append(0xd9930810);
    t.append(0xb38bae12); t.append(0xdccf3f2e); t.append(0x5512721f); t.append(0x2e6b7124); t.append(0x501adde6); t.append(0x9f84cd87);
    t.append(0x7a584718); t.append(0x7408da17); t.append(0xbc9f9abc); t.append(0xe94b7d8c); t.append(0xec7aec3a); t.append(0xdb851dfa);
    t.append(0x63094366); t.append(0xc464c3d2); t.append(0xef1c1847); t.append(0x3215d908); t.append(0xdd433b37); t.append(0x24c2ba16);
    t.append(0x12a14d43); t.append(0x2a65c451); t.append(0x50940002); t.append(0x133ae4dd); t.append(0x71dff89e); t.append(0x10314e55);
    t.append(0x81ac77d6); t.append(0x5f11199b); t.append(0x043556f1); t.append(0xd7a3c76b); t.append(0x3c11183b); t.append(0x5924a509);
    t.append(0xf28fe6ed); t.append(0x97f1fbfa); t.append(0x9ebabf2c); t.append(0x1e153c6e); t.append(0x86e34570); t.append(0xeae96fb1);
    t.append(0x860e5e0a); t.append(0x5a3e2ab3); t.append(0x771fe71c); t.append(0x4e3d06fa); t.append(0x2965dcb9); t.append(0x99e71d0f);
    t.append(0x803e89d6); t.append(0x5266c825); t.append(0x2e4cc978); t.append(0x9c10b36a); t.append(0xc6150eba); t.append(0x94e2ea78);
    t.append(0xa5fc3c53); t.append(0x1e0a2df4); t.append(0xf2f74ea7); t.append(0x361d2b3d); t.append(0x1939260f); t.append(0x19c27960);
    t.append(0x5223a708); t.append(0xf71312b6); t.append(0xebadfe6e); t.append(0xeac31f66); t.append(0xe3bc4595); t.append(0xa67bc883);
    t.append(0xb17f37d1); t.append(0x018cff28); t.append(0xc332ddef); t.append(0xbe6c5aa5); t.append(0x65582185); t.append(0x68ab9802);
    t.append(0xeecea50f); t.append(0xdb2f953b); t.append(0x2aef7dad); t.append(0x5b6e2f84); t.append(0x1521b628); t.append(0x29076170);
    t.append(0xecdd4775); t.append(0x619f1510); t.append(0x13cca830); t.append(0xeb61bd96); t.append(0x0334fe1e); t.append(0xaa0363cf);
    t.append(0xb5735c90); t.append(0x4c70a239); t.append(0xd59e9e0b); t.append(0xcbaade14); t.append(0xeecc86bc); t.append(0x60622ca7);
    t.append(0x9cab5cab); t.append(0xb2f3846e); t.append(0x648b1eaf); t.append(0x19bdf0ca); t.append(0xa02369b9); t.append(0x655abb50);
    t.append(0x40685a32); t.append(0x3c2ab4b3); t.append(0x319ee9d5); t.append(0xc021b8f7); t.append(0x9b540b19); t.append(0x875fa099);
    t.append(0x95f7997e); t.append(0x623d7da8); t.append(0xf837889a); t.append(0x97e32d77); t.append(0x11ed935f); t.append(0x16681281);
    t.append(0x0e358829); t.append(0xc7e61fd6); t.append(0x96dedfa1); t.append(0x7858ba99); t.append(0x57f584a5); t.append(0x1b227263);
    t.append(0x9b83c3ff); t.append(0x1ac24696); t.append(0xcdb30aeb); t.append(0x532e3054); t.append(0x8fd948e4); t.append(0x6dbc3128);
    t.append(0x58ebf2ef); t.append(0x34c6ffea); t.append(0xfe28ed61); t.append(0xee7c3c73); t.append(0x5d4a14d9); t.append(0xe864b7e3);
    t.append(0x42105d14); t.append(0x203e13e0); t.append(0x45eee2b6); t.append(0xa3aaabea); t.append(0xdb6c4f15); t.append(0xfacb4fd0);
    t.append(0xc742f442); t.append(0xef6abbb5); t.append(0x654f3b1d); t.append(0x41cd2105); t.append(0xd81e799e); t.append(0x86854dc7);
    t.append(0xe44b476a); t.append(0x3d816250); t.append(0xcf62a1f2); t.append(0x5b8d2646); t.append(0xfc8883a0); t.append(0xc1c7b6a3);
    t.append(0x7f1524c3); t.append(0x69cb7492); t.append(0x47848a0b); t.append(0x5692b285); t.append(0x095bbf00); t.append(0xad19489d);
    t.append(0x1462b174); t.append(0x23820e00); t.append(0x58428d2a); t.append(0x0c55f5ea); t.append(0x1dadf43e); t.append(0x233f7061);
    t.append(0x3372f092); t.append(0x8d937e41); t.append(0xd65fecf1); t.append(0x6c223bdb); t.append(0x7cde3759); t.append(0xcbee7460);
    t.append(0x4085f2a7); t.append(0xce77326e); t.append(0xa6078084); t.append(0x19f8509e); t.append(0xe8efd855); t.append(0x61d99735);
    t.append(0xa969a7aa); t.append(0xc50c06c2); t.append(0x5a04abfc); t.append(0x800bcadc); t.append(0x9e447a2e); t.append(0xc3453484);
    t.append(0xfdd56705); t.append(0x0e1e9ec9); t.append(0xdb73dbd3); t.append(0x105588cd); t.append(0x675fda79); t.append(0xe3674340);
    t.append(0xc5c43465); t.append(0x713e38d8); t.append(0x3d28f89e); t.append(0xf16dff20); t.append(0x153e21e7); t.append(0x8fb03d4a);
    t.append(0xe6e39f2b); t.append(0xdb83adf7); t.append(0xe93d5a68); t.append(0x948140f7); t.append(0xf64c261c); t.append(0x94692934);
    t.append(0x411520f7); t.append(0x7602d4f7); t.append(0xbcf46b2e); t.append(0xd4a20068); t.append(0xd4082471); t.append(0x3320f46a);
    t.append(0x43b7d4b7); t.append(0x500061af); t.append(0x1e39f62e); t.append(0x97244546); t.append(0x14214f74); t.append(0xbf8b8840);
    t.append(0x4d95fc1d); t.append(0x96b591af); t.append(0x70f4ddd3); t.append(0x66a02f45); t.append(0xbfbc09ec); t.append(0x03bd9785);
    t.append(0x7fac6dd0); t.append(0x31cb8504); t.append(0x96eb27b3); t.append(0x55fd3941); t.append(0xda2547e6); t.append(0xabca0a9a);
    t.append(0x28507825); t.append(0x530429f4); t.append(0x0a2c86da); t.append(0xe9b66dfb); t.append(0x68dc1462); t.append(0xd7486900);
    t.append(0x680ec0a4); t.append(0x27a18dee); t.append(0x4f3ffea2); t.append(0xe887ad8c); t.append(0xb58ce006); t.append(0x7af4d6b6);
    t.append(0xaace1e7c); t.append(0xd3375fec); t.append(0xce78a399); t.append(0x406b2a42); t.append(0x20fe9e35); t.append(0xd9f385b9);
    t.append(0xee39d7ab); t.append(0x3b124e8b); t.append(0x1dc9faf7); t.append(0x4b6d1856); t.append(0x26a36631); t.append(0xeae397b2);
    t.append(0x3a6efa74); t.append(0xdd5b4332); t.append(0x6841e7f7); t.append(0xca7820fb); t.append(0xfb0af54e); t.append(0xd8feb397);
    t.append(0x454056ac); t.append(0xba489527); t.append(0x55533a3a); t.append(0x20838d87); t.append(0xfe6ba9b7); t.append(0xd096954b);
    t.append(0x55a867bc); t.append(0xa1159a58); t.append(0xcca92963); t.append(0x99e1db33); t.append(0xa62a4a56); t.append(0x3f3125f9);
    t.append(0x5ef47e1c); t.append(0x9029317c); t.append(0xfdf8e802); t.append(0x04272f70); t.append(0x80bb155c); t.append(0x05282ce3);
    t.append(0x95c11548); t.append(0xe4c66d22); t.append(0x48c1133f); t.append(0xc70f86dc); t.append(0x07f9c9ee); t.append(0x41041f0f);
    t.append(0x404779a4); t.append(0x5d886e17); t.append(0x325f51eb); t.append(0xd59bc0d1); t.append(0xf2bcc18f); t.append(0x41113564);
    t.append(0x257b7834); t.append(0x602a9c60); t.append(0xdff8e8a3); t.append(0x1f636c1b); t.append(0x0e12b4c2); t.append(0x02e1329e);
    t.append(0xaf664fd1); t.append(0xcad18115); t.append(0x6b2395e0); t.append(0x333e92e1); t.append(0x3b240b62); t.append(0xeebeb922);
    t.append(0x85b2a20e); t.append(0xe6ba0d99); t.append(0xde720c8c); t.append(0x2da2f728); t.append(0xd0127845); t.append(0x95b794fd);
    t.append(0x647d0862); t.append(0xe7ccf5f0); t.append(0x5449a36f); t.append(0x877d48fa); t.append(0xc39dfd27); t.append(0xf33e8d1e);
    t.append(0x0a476341); t.append(0x992eff74); t.append(0x3a6f6eab); t.append(0xf4f8fd37); t.append(0xa812dc60); t.append(0xa1ebddf8);
    t.append(0x991be14c); t.append(0xdb6e6b0d); t.append(0xc67b5510); t.append(0x6d672c37); t.append(0x2765d43b); t.append(0xdcd0e804);
    t.append(0xf1290dc7); t.append(0xcc00ffa3); t.append(0xb5390f92); t.append(0x690fed0b); t.append(0x667b9ffb); t.append(0xcedb7d9c);
    t.append(0xa091cf0b); t.append(0xd9155ea3); t.append(0xbb132f88); t.append(0x515bad24); t.append(0x7b9479bf); t.append(0x763bd6eb);
    t.append(0x37392eb3); t.append(0xcc115979); t.append(0x8026e297); t.append(0xf42e312d); t.append(0x6842ada7); t.append(0xc66a2b3b);
    t.append(0x12754ccc); t.append(0x782ef11c); t.append(0x6a124237); t.append(0xb79251e7); t.append(0x06a1bbe6); t.append(0x4bfb6350);
    t.append(0x1a6b1018); t.append(0x11caedfa); t.append(0x3d25bdd8); t.append(0xe2e1c3c9); t.append(0x44421659); t.append(0x0a121386);
    t.append(0xd90cec6e); t.append(0xd5abea2a); t.append(0x64af674e); t.append(0xda86a85f); t.append(0xbebfe988); t.append(0x64e4c3fe);
    t.append(0x9dbc8057); t.append(0xf0f7c086); t.append(0x60787bf8); t.append(0x6003604d); t.append(0xd1fd8346); t.append(0xf6381fb0);
    t.append(0x7745ae04); t.append(0xd736fccc); t.append(0x83426b33); t.append(0xf01eab71); t.append(0xb0804187); t.append(0x3c005e5f);
    t.append(0x77a057be); t.append(0xbde8ae24); t.append(0x55464299); t.append(0xbf582e61); t.append(0x4e58f48f); t.append(0xf2ddfda2);
    t.append(0xf474ef38); t.append(0x8789bdc2); t.append(0x5366f9c3); t.append(0xc8b38e74); t.append(0xb475f255); t.append(0x46fcd9b9);
    t.append(0x7aeb2661); t.append(0x8b1ddf84); t.append(0x846a0e79); t.append(0x915f95e2); t.append(0x466e598e); t.append(0x20b45770);
    t.append(0x8cd55591); t.append(0xc902de4c); t.append(0xb90bace1); t.append(0xbb8205d0); t.append(0x11a86248); t.append(0x7574a99e);
    t.append(0xb77f19b6); t.append(0xe0a9dc09); t.append(0x662d09a1); t.append(0xc4324633); t.append(0xe85a1f02); t.append(0x09f0be8c);
    t.append(0x4a99a025); t.append(0x1d6efe10); t.append(0x1ab93d1d); t.append(0x0ba5a4df); t.append(0xa186f20f); t.append(0x2868f169);
    t.append(0xdcb7da83); t.append(0x573906fe); t.append(0xa1e2ce9b); t.append(0x4fcd7f52); t.append(0x50115e01); t.append(0xa70683fa);
    t.append(0xa002b5c4); t.append(0x0de6d027); t.append(0x9af88c27); t.append(0x773f8641); t.append(0xc3604c06); t.append(0x61a806b5);
    t.append(0xf0177a28); t.append(0xc0f586e0); t.append(0x006058aa); t.append(0x30dc7d62); t.append(0x11e69ed7); t.append(0x2338ea63);
    t.append(0x53c2dd94); t.append(0xc2c21634); t.append(0xbbcbee56); t.append(0x90bcb6de); t.append(0xebfc7da1); t.append(0xce591d76);
    t.append(0x6f05e409); t.append(0x4b7c0188); t.append(0x39720a3d); t.append(0x7c927c24); t.append(0x86e3725f); t.append(0x724d9db9);
    t.append(0x1ac15bb4); t.append(0xd39eb8fc); t.append(0xed545578); t.append(0x08fca5b5); t.append(0xd83d7cd3); t.append(0x4dad0fc4);
    t.append(0x1e50ef5e); t.append(0xb161e6f8); t.append(0xa28514d9); t.append(0x6c51133c); t.append(0x6fd5c7e7); t.append(0x56e14ec4);
    t.append(0x362abfce); t.append(0xddc6c837); t.append(0xd79a3234); t.append(0x92638212); t.append(0x670efa8e); t.append(0x406000e0);
    t.append(0x3a39ce37); t.append(0xd3faf5cf); t.append(0xabc27737); t.append(0x5ac52d1b); t.append(0x5cb0679e); t.append(0x4fa33742);
    t.append(0xd3822740); t.append(0x99bc9bbe); t.append(0xd5118e9d); t.append(0xbf0f7315); t.append(0xd62d1c7e); t.append(0xc700c47b);
    t.append(0xb78c1b6b); t.append(0x21a19045); t.append(0xb26eb1be); t.append(0x6a366eb4); t.append(0x5748ab2f); t.append(0xbc946e79);
    t.append(0xc6a376d2); t.append(0x6549c2c8); t.append(0x530ff8ee); t.append(0x468dde7d); t.append(0xd5730a1d); t.append(0x4cd04dc6);
    t.append(0x2939bbdb); t.append(0xa9ba4650); t.append(0xac9526e8); t.append(0xbe5ee304); t.append(0xa1fad5f0); t.append(0x6a2d519a);
    t.append(0x63ef8ce2); t.append(0x9a86ee22); t.append(0xc089c2b8); t.append(0x43242ef6); t.append(0xa51e03aa); t.append(0x9cf2d0a4);
    t.append(0x83c061ba); t.append(0x9be96a4d); t.append(0x8fe51550); t.append(0xba645bd6); t.append(0x2826a2f9); t.append(0xa73a3ae1);
    t.append(0x4ba99586); t.append(0xef5562e9); t.append(0xc72fefd3); t.append(0xf752f7da); t.append(0x3f046f69); t.append(0x77fa0a59);
    t.append(0x80e4a915); t.append(0x87b08601); t.append(0x9b09e6ad); t.append(0x3b3ee593); t.append(0xe990fd5a); t.append(0x9e34d797);
    t.append(0x2cf0b7d9); t.append(0x022b8b51); t.append(0x96d5ac3a); t.append(0x017da67d); t.append(0xd1cf3ed6); t.append(0x7c7d2d28);
    t.append(0x1f9f25cf); t.append(0xadf2b89b); t.append(0x5ad6b472); t.append(0x5a88f54c); t.append(0xe029ac71); t.append(0xe019a5e6);
    t.append(0x47b0acfd); t.append(0xed93fa9b); t.append(0xe8d3c48d); t.append(0x283b57cc); t.append(0xf8d56629); t.append(0x79132e28);
    t.append(0x785f0191); t.append(0xed756055); t.append(0xf7960e44); t.append(0xe3d35e8c); t.append(0x15056dd4); t.append(0x88f46dba);
    t.append(0x03a16125); t.append(0x0564f0bd); t.append(0xc3eb9e15); t.append(0x3c9057a2); t.append(0x97271aec); t.append(0xa93a072a);
    t.append(0x1b3f6d9b); t.append(0x1e6321f5); t.append(0xf59c66fb); t.append(0x26dcf319); t.append(0x7533d928); t.append(0xb155fdf5);
    t.append(0x03563482); t.append(0x8aba3cbb); t.append(0x28517711); t.append(0xc20ad9f8); t.append(0xabcc5167); t.append(0xccad925f);
    t.append(0x4de81751); t.append(0x3830dc8e); t.append(0x379d5862); t.append(0x9320f991); t.append(0xea7a90c2); t.append(0xfb3e7bce);
    t.append(0x5121ce64); t.append(0x774fbe32); t.append(0xa8b6e37e); t.append(0xc3293d46); t.append(0x48de5369); t.append(0x6413e680);
    t.append(0xa2ae0810); t.append(0xdd6db224); t.append(0x69852dfd); t.append(0x09072166); t.append(0xb39a460a); t.append(0x6445c0dd);
    t.append(0x586cdecf); t.append(0x1c20c8ae); t.append(0x5bbef7dd); t.append(0x1b588d40); t.append(0xccd2017f); t.append(0x6bb4e3bb);
    t.append(0xdda26a7e); t.append(0x3a59ff45); t.append(0x3e350a44); t.append(0xbcb4cdd5); t.append(0x72eacea8); t.append(0xfa6484bb);
    t.append(0x8d6612ae); t.append(0xbf3c6f47); t.append(0xd29be463); t.append(0x542f5d9e); t.append(0xaec2771b); t.append(0xf64e6370);
    t.append(0x740e0d8d); t.append(0xe75b1357); t.append(0xf8721671); t.append(0xaf537d5d); t.append(0x4040cb08); t.append(0x4eb4e2cc);
    t.append(0x34d2466a); t.append(0x0115af84); t.append(0xe1b00428); t.append(0x95983a1d); t.append(0x06b89fb4); t.append(0xce6ea048);
    t.append(0x6f3f3b82); t.append(0x3520ab82); t.append(0x011a1d4b); t.append(0x277227f8); t.append(0x611560b1); t.append(0xe7933fdc);
    t.append(0xbb3a792b); t.append(0x344525bd); t.append(0xa08839e1); t.append(0x51ce794b); t.append(0x2f32c9b7); t.append(0xa01fbac9);
    t.append(0xe01cc87e); t.append(0xbcc7d1f6); t.append(0xcf0111c3); t.append(0xa1e8aac7); t.append(0x1a908749); t.append(0xd44fbd9a);
    t.append(0xd0dadecb); t.append(0xd50ada38); t.append(0x0339c32a); t.append(0xc6913667); t.append(0x8df9317c); t.append(0xe0b12b4f);
    t.append(0xf79e59b7); t.append(0x43f5bb3a); t.append(0xf2d519ff); t.append(0x27d9459c); t.append(0xbf97222c); t.append(0x15e6fc2a);
    t.append(0x0f91fc71); t.append(0x9b941525); t.append(0xfae59361); t.append(0xceb69ceb); t.append(0xc2a86459); t.append(0x12baa8d1);
    t.append(0xb6c1075e); t.append(0xe3056a0c); t.append(0x10d25065); t.append(0xcb03a442); t.append(0xe0ec6e0e); t.append(0x1698db3b);
    t.append(0x4c98a0be); t.append(0x3278e964); t.append(0x9f1f9532); t.append(0xe0d392df); t.append(0xd3a0342b); t.append(0x8971f21e);
    t.append(0x1b0a7441); t.append(0x4ba3348c); t.append(0xc5be7120); t.append(0xc37632d8); t.append(0xdf359f8d); t.append(0x9b992f2e);
    t.append(0xe60b6f47); t.append(0x0fe3f11d); t.append(0xe54cda54); t.append(0x1edad891); t.append(0xce6279cf); t.append(0xcd3e7e6f);
    t.append(0x1618b166); t.append(0xfd2c1d05); t.append(0x848fd2c5); t.append(0xf6fb2299); t.append(0xf523f357); t.append(0xa6327623);
    t.append(0x93a83531); t.append(0x56cccd02); t.append(0xacf08162); t.append(0x5a75ebb5); t.append(0x6e163697); t.append(0x88d273cc);
    t.append(0xde966292); t.append(0x81b949d0); t.append(0x4c50901b); t.append(0x71c65614); t.append(0xe6c6c7bd); t.append(0x327a140a);
    t.append(0x45e1d006); t.append(0xc3f27b9a); t.append(0xc9aa53fd); t.append(0x62a80f00); t.append(0xbb25bfe2); t.append(0x35bdd2f6);
    t.append(0x71126905); t.append(0xb2040222); t.append(0xb6cbcf7c); t.append(0xcd769c2b); t.append(0x53113ec0); t.append(0x1640e3d3);
    t.append(0x38abbd60); t.append(0x2547adf0); t.append(0xba38209c); t.append(0xf746ce76); t.append(0x77afa1c5); t.append(0x20756060);
    t.append(0x85cbfe4e); t.append(0x8ae88dd8); t.append(0x7aaaf9b0); t.append(0x4cf9aa7e); t.append(0x1948c25c); t.append(0x02fb8a8c);
    t.append(0x01c36ae4); t.append(0xd6ebe1f9); t.append(0x90d4f869); t.append(0xa65cdea0); t.append(0x3f09252d); t.append(0xc208e69f);
    t.append(0xb74e6132); t.append(0xce77e25b); t.append(0x578fdfe3); t.append(0x3ac372e6)
    return t

fn blowfish_f(x:UInt32, state:List[UInt32]) -> UInt32:
    let a=Int(x>>24);let b=Int((x>>16)&255);let c=Int((x>>8)&255);let d=Int(x&255)
    let sum1=(UInt64(state[18+a])+UInt64(state[274+b]))&UInt64(0xffffffff)
    let mixed=UInt32(sum1)^state[530+c]
    return UInt32((UInt64(mixed)+UInt64(state[786+d]))&UInt64(0xffffffff))

fn blowfish_block(block:UInt64, state:List[UInt32], decrypt:Bool) -> UInt64:
    var left=UInt32(block>>32);var right=UInt32(block&UInt64(0xffffffff))
    if decrypt:left^=state[17]
    else:left^=state[0]
    for round in range(16):
        var index=round+1
        if decrypt:index=16-round
        right^=blowfish_f(left,state)^state[index]
        let tmp=left;left=right;right=tmp
    let tmp=left;left=right;right=tmp
    if decrypt:right^=state[0]
    else:right^=state[17]
    return (UInt64(left)<<32)|UInt64(right)

fn blowfish_setup(selector:Int) -> List[UInt32]:
    var state=blowfish_initial_words()
    var key=List[UInt8](capacity=26)
    if selector==0:
        for i in range(26):key.append(UInt8(97+i))
    else:
        key.append(87);key.append(104);key.append(111);key.append(32);key.append(105);key.append(115)
        key.append(32);key.append(74);key.append(111);key.append(104);key.append(110);key.append(32)
        key.append(71);key.append(97);key.append(108);key.append(116);key.append(63)
    var pos=0
    for i in range(18):
        var word:UInt32=0
        for _ in range(4):
            word=(word<<8)|UInt32(key[pos]);pos=(pos+1)%len(key)
        state[i]^=word
    var block:UInt64=0
    for pair in range(521):
        block=blowfish_block(block,state,False)
        state[pair*2]=UInt32(block>>32)
        state[pair*2+1]=UInt32(block&UInt64(0xffffffff))
    return state

@export("cbench_blowfish_cbc")
fn cbench_blowfish_cbc(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<19 or length>43:return -1
    if input[0]<0 or input[0]>1 or input[1]<0 or input[1]>1 or input[2]<1 or input[2]>4:return -1
    let blocks=Int(input[2]);let needed=8*blocks
    if length!=c_size_t(11+needed):return -1
    for i in range(3,11+needed):
        if input[i]<0 or input[i]>255:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(needed):return -2
    let state=blowfish_setup(Int(input[1]))
    var previous:UInt64=0
    for i in range(8):previous=(previous<<8)|UInt64(input[3+i])
    for b in range(blocks):
        var block:UInt64=0
        for i in range(8):block=(block<<8)|UInt64(input[11+8*b+i])
        var result:UInt64=0
        if input[0]==0:
            result=blowfish_block(block^previous,state,False)
            previous=result
        else:
            result=blowfish_block(block,state,True)^previous
            previous=block
        for i in range(8):out[8*b+i]=UInt8((result>>UInt(56-8*i))&255)
    return Int64(needed)

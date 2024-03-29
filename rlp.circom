pragma circom 2.0.0;

include "./helper.circom";

template Rlp() {
    signal input nonce;
    signal input balance; 
    signal input storage_hash[32];
    signal input code_hash[32];

    signal output rlp_encoded[79];
    signal output rlp_encoded_len;

    // Updated RLP lengths
    signal nonceRlpLen; 
    signal balanceRlpLen;
    var storageHashRlpLen = 33; // 32 bytes + 1 byte length prefix
    var codeHashRlpLen = 33; // 32 bytes + 1 byte length prefix

    // Placeholder signals for RLP encoded parts
    signal nonceRlpEncoded[5];
    signal rlpEncodedBalance[10];
    signal storageHashRlpEncoded[33];
    signal codeHashRlpEncoded[33];

    // RLP Encoding for nonce
    component bdNonce = ByteDecompose(5);
    bdNonce.num <== nonce;
 
    signal nonceIsSingleByte;
    nonceIsSingleByte <-- (nonce < 0x80) ? 1 : 0;

    nonceRlpEncoded[0] <== nonceIsSingleByte * nonce + (1 - nonceIsSingleByte) * (0x80 + 4);

    for (var i = 1; i < 5; i++) {
        nonceRlpEncoded[5-i] <== (1 - nonceIsSingleByte) * bdNonce.bytes[i];
    }

    nonceRlpLen <== nonceIsSingleByte + (1 - nonceIsSingleByte) * 5;
     
    // RLP Encoding for balance
    component bdBalance = ByteDecompose(9);
    bdBalance.num <== balance;

    signal balanceIsSingleByte;
    balanceIsSingleByte <-- (balance < 0x80) ? 1 : 0;

    rlpEncodedBalance[0] <== balanceIsSingleByte * balance + (1 - balanceIsSingleByte) * (0x80 + 9);

    for (var i = 0; i < 9; i++) {
        rlpEncodedBalance[9-i] <== (1 - balanceIsSingleByte) * bdBalance.bytes[i];
    }

    balanceRlpLen <== balanceIsSingleByte + (1 - balanceIsSingleByte) * 10;

    // RLP Encoding for storage_hash
    storageHashRlpEncoded[0] <== 0x80 + 32;
    
    for (var i = 0; i < 32; i++) {
        storageHashRlpEncoded[i + 1] <== storage_hash[i]; 
    }

    // RLP Encoding for code_hash
    codeHashRlpEncoded[0] <== 0x80 + 32;
    
    for (var i = 0; i < 32; i++) {
        codeHashRlpEncoded[i + 1] <== code_hash[i];
    }

    // Concatenation Steps
    component concat1 = Concat(5, 10);
    concat1.a <== nonceRlpEncoded;
    concat1.aLen <== nonceRlpLen;
    concat1.b <== rlpEncodedBalance;
    concat1.bLen <== balanceRlpLen;

    component concat2 = Concat(15, 33);
    for (var i = 0; i < 15; i++) { 
        concat2.a[i] <== concat1.out[i];
    }
    concat2.aLen <== concat1.outLen;
    concat2.b <== storageHashRlpEncoded;
    concat2.bLen <== storageHashRlpLen;

    component concat3 = Concat(48, 33); 
    for (var i = 0; i < 48; i++) { 
        concat3.a[i] <== concat2.out[i]; 
    }
    concat3.aLen <== concat2.outLen;
    concat3.b <== codeHashRlpEncoded;
    concat3.bLen <== codeHashRlpLen;

    rlp_encoded[0] <== 0xf8; 
    rlp_encoded[1] <== 77; 

    for (var i = 0; i < 77; i++) {
        rlp_encoded[i + 2] <== concat3.out[i];
    }

    rlp_encoded_len <== concat3.outLen;
}

component main = Rlp();

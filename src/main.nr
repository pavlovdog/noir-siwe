mod siwe;

fn main(message: [u8; 8192], pub_key_x: [u8; 32], pub_key_y: [u8; 32], signature: [u8; 64]) {
    let siwe = siwe::SiweMessage::from_message(message);

    assert(siwe.chainId == 1, "Chain ID is not 1");

    let result = siwe.ecrecover(pub_key_x, pub_key_y, signature);

    assert(result == 0x7b1afe2745533d852d6fd5a677f14c074210d896, "Ecrecover failed");
    assert(siwe.address == 0x7b1afe2745533d852d6fd5a677f14c074210d896, "Address is not correct");
}

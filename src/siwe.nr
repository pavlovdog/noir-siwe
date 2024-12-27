use crate::utils::string;
use dep::ecrecover;
use dep::std;
use dep::string_search;

global PREFIX: [u8; 26] = [
    25, 69, 116, 104, 101, 114, 101, 117, 109, 32, 83, 105, 103, 110, 101, 100, 32, 77, 101, 115,
    115, 97, 103, 101, 58, 10,
];

global MAX_LENGTH: u32 = 999;

pub fn getDigest<let N: u32>(message: [u8; N]) -> [u8; 32] {
    assert(N <= MAX_LENGTH, "Message length must be less than or equal to 999");

    // Convert message length to ASCII digits
    let message_len = message.len() as u32;
    let mut length_str: [u8; 3] = [0; 3]; // Max 3 digits for MAX_LENGTH of 500
    let mut length_str_len = 0;

    if message_len >= 100 {
        length_str[length_str_len] = (message_len / 100) as u8 + 48; // Add ASCII '0' (48)
        length_str_len += 1;
    }

    if message_len >= 10 {
        length_str[length_str_len] = ((message_len % 100) / 10) as u8 + 48;
        length_str_len += 1;
    }

    length_str[length_str_len] = (message_len % 10) as u8 + 48;
    length_str_len += 1;

    let mut prefixed_message: [u8; MAX_LENGTH] = [0; MAX_LENGTH];

    // Copy prefix
    for i in 0..26 {
        prefixed_message[i] = PREFIX[i];
    }

    // Copy length string
    for i in 0..length_str_len {
        prefixed_message[i + 26] = length_str[i];
    }

    // Copy message
    for i in 0..message.len() {
        prefixed_message[i + 26 + length_str_len] = message[i];
    }

    let prefixed_length = message.len() + 26 + length_str_len;

    let prefixed_digest = std::hash::keccak256(prefixed_message, prefixed_length as u32);

    prefixed_digest
}

pub struct SiweMessage<let N: u32> {
    message: [u8; N],
    pub chainId: u64,
    pub address: Field
}

fn get_chainId<let N: u32>(MESSAGE: [u8; N]) -> u64 {
    let PREFIX = "Chain ID: ";
    let POSTFIX = "Nonce: ";

    let message: string_search::StringBody8192 =
        string_search::StringBody8192::new(MESSAGE, MESSAGE.len());

    let prefix: string_search::SubString32 = string_search::SubString32::new(PREFIX.as_bytes(), 10);

    let postfix: string_search::SubString32 =
        string_search::SubString32::new(POSTFIX.as_bytes(), 7);

    let (prefix_match, prefix_position): (bool, u32) = message.substring_match(prefix);
    let (postfix_match, postfix_position): (bool, u32) = message.substring_match(postfix);

    assert(prefix_match & postfix_match, "Failed to find Chain ID in message");

    string::to_uint_slice(
        MESSAGE,
        prefix_position as u64 + 10,
        postfix_position as u64 - 1,
    )
}

fn get_address<let N: u32>(MESSAGE: [u8; N]) -> Field {
    let PREFIX = "wants you to sign in with your Ethereum account:\n";
    let PREFIX_LENGTH = 49;

    let message: string_search::StringBody8192 =
        string_search::StringBody8192::new(MESSAGE, MESSAGE.len());

    let prefix: string_search::SubString64 = string_search::SubString64::new(PREFIX.as_bytes(), 49);

    let (prefix_match, prefix_position): (bool, u32) = message.substring_match(prefix);

    assert(prefix_match, "Failed to find address in message");

    let mut addr: Field = 0;

    for i in 2..42 {
        let hex_char = MESSAGE[prefix_position as u64 + PREFIX_LENGTH + i];
        let byte = hex_to_int(hex_char) as Field;
        addr = (addr * 16) + byte;
    }

    addr
}

fn hex_to_int(c: u8) -> u8 {
    if (c >= 48) & (c <= 57) { // '0' to '9'
        c - 48
    } else if (c >= 65) & (c <= 70) { // 'A' to 'F'
        c - 55
    } else if (c >= 97) & (c <= 102) { // 'a' to 'f'
        c - 87
    } else {
        0
    }
}

impl<let N: u32> SiweMessage<N> {
    pub fn from_message(message: [u8; N]) -> Self {
        let chainId = get_chainId(message);
        let address = get_address(message);
        Self { message, chainId, address }
    }

    pub fn ecrecover(self, pub_key_x: [u8; 32], pub_key_y: [u8; 32], signature: [u8; 64]) -> Field {
        let digest = getDigest(self.message);

        let addr = ecrecover::ecrecover(pub_key_x, pub_key_y, signature, digest);

        addr
    }
}

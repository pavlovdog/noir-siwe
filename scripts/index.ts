import { createWalletClient, hashMessage, Hex, http, keccak256, recoverPublicKey, toPrefixedMessage } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { generatePrivateKey } from 'viem/accounts'
import { SiweMessage } from 'siwe'
import { mainnet } from 'viem/chains'
import { generateSiweNonce } from 'viem/siwe'

const PRIVATE_KEY = '0x000000000000000000000000000000000000000000000000000000000000dead'

const MESSAGE = `https://localhost wants you to sign in with your Ethereum account:
0x7B1aFE2745533D852d6fD5A677F14c074210d896

Sign in with Ethereum to the app.

URI: http://localhost:3000
Version: 1
Chain ID: 1
Nonce: 9ee17d6fb66302f77485feee3542b12d412581d284ce5b310f13939732398e89b01ea74f3e363b4815bc6f87cf187675
Issued At: 2024-12-26T19:19:43.784Z`

// const MESSAGE = 'Test 123'

const prepareInputs = async (
    message: string,
    signature: Hex
): Promise<{
    message: number[],
    signature: number[],
    publicKeyX: number[],
    publicKeyY: number[],
    digest: number[]
}> => {
    const messageU8 = Array.from(new TextEncoder().encode(message));
    const signatureU8 = Array.from(new Uint8Array(Buffer.from(signature.replace('0x', ''), 'hex')))

    const publicKey = await recoverPublicKey({
        hash: hashMessage(message),
        signature
    })

    const pubKeyX = publicKey.slice(4, 68)
    const pubKeyY = publicKey.slice(68)

    // const digest = keccak256(new TextEncoder().encode(message))
    const digest = hashMessage(message)

    return {
        message: messageU8,
        signature: signatureU8.slice(0, 64),
        publicKeyX: Array.from(new Uint8Array(Buffer.from(pubKeyX, 'hex'))),
        publicKeyY: Array.from(new Uint8Array(Buffer.from(pubKeyY, 'hex'))),
        digest: Array.from(new Uint8Array(Buffer.from(digest.replace('0x', ''), 'hex')))
    }
}

async function main() {
    // Generate random private key and create account
    const account = privateKeyToAccount(PRIVATE_KEY)

    // Create wallet client
    const client = createWalletClient({
        account,
        chain: mainnet,
        transport: http()
    })

    // // Create SIWE message
    // const message = new SiweMessage({
    //     scheme: 'https',
    //     domain: 'localhost',
    //     address: account.address,
    //     statement: 'Sign in with Ethereum to the app.',
    //     uri: 'http://localhost:3000',
    //     version: '1',
    //     chainId: mainnet.id,
    //     nonce: generateSiweNonce(),
    //     issuedAt: new Date().toISOString()
    // })

    // // Convert message to string
    // const messageToSign = message.prepareMessage()
    // console.log('Message to sign')
    // console.log(messageToSign)

    // Sign message
    const signature = await client.signMessage({
        message: MESSAGE,
    })

    const inputs = await prepareInputs(MESSAGE, signature)

    console.log('Public key X as [u8]')
    console.log(JSON.stringify(inputs.publicKeyX))
    console.log('Public key Y as [u8]')
    console.log(JSON.stringify(inputs.publicKeyY))


    console.log('Message as [u8]')
    console.log(JSON.stringify(inputs.message))
    console.log('Signature as [u8]')
    console.log(JSON.stringify(inputs.signature))

    console.log('Digest')
    console.log(JSON.stringify(inputs.digest))

    // // Log Ethereum Signed Message prefix as [u8]
    // const prefix = `\x19Ethereum Signed Message:\n`;
    // const prefixU8 = Array.from(new TextEncoder().encode(prefix))
    // console.log('Ethereum Signed Message prefix as [u8]')
    // console.log(JSON.stringify(prefixU8))
}

main().catch(console.error)

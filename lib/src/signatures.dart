import 'package:nanodart/nanodart.dart' as nd;
import 'package:nanoutil/src/blake.dart';
import 'package:cryptography/cryptography.dart';

import 'derivations.dart';

class NanoSignatures {
  static String signBlock(String hash, String privateKey) {
    return nd.NanoSignatures.signBlock(hash, privateKey);
  }

  static Future<bool> verify(
      String message, String signature, String address) async {
    final DartEd25519Blake blake = DartEd25519Blake();

    final SimplePublicKey pubKey = SimplePublicKey(
      nd.NanoHelpers.hexToBytes(NanoDerivations.addressToPublicKey(address)),
      type: KeyPairType.ed25519,
    );

    bool valid = await blake.verify(
      nd.NanoHelpers.hexToBytes(message),
      signature: Signature(
        nd.NanoHelpers.hexToBytes(signature),
        publicKey: pubKey,
      ),
    );
    return valid;
  }

  static String hash(String message) {
    return nd.NanoHelpers.byteToHex(
      nd.Blake2b.digest256([nd.NanoHelpers.stringToBytesUtf8(message)]),
    ).toUpperCase();
  }

  static String signMessage(String message, String privateKey) {
    return nd.NanoSignatures.signBlock(
      hash(message),
      privateKey,
    );
  }

  static Future<bool> verifyMessage(
    String message,
    String signature,
    String address,
  ) async {
    final String hashedMessage = hash(message);

    return await verify(
      hashedMessage,
      signature,
      address,
    );
  }

  static String computeStateHash(
    NanoBasedCurrency currencyType,
    String account,
    String previous,
    String representative,
    BigInt balance,
    String link,
  ) {
    late int accountType;
    switch (currencyType) {
      case NanoBasedCurrency.NANO:
        accountType = nd.NanoAccountType.NANO;
        break;
      case NanoBasedCurrency.BANANO:
        accountType = nd.NanoAccountType.BANANO;
        break;
      case NanoBasedCurrency.NYANO:
      default:
        accountType = nd.NanoAccountType.NANO;
        break;
    }
    return nd.NanoBlocks.computeStateHash(
      accountType,
      account,
      previous,
      representative,
      balance,
      link,
    );
  }
}

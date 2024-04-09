import 'package:nanodart/nanodart.dart' as nd;

import 'derivations.dart';

class NanoSignatures {
  static String signBlock(String hash, String privateKey) {
    return nd.NanoSignatures.signBlock(hash, privateKey);
  }

  static String sign(String message, String privateKey) {
    return nd.NanoHelpers.byteToHex(
      nd.Signature.detached(
        nd.NanoHelpers.stringToBytesUtf8(message),
        nd.NanoHelpers.hexToBytes(privateKey),
      ),
    );
  }

  static bool verify(String message, String signature, String publicKey) {
    return nd.Signature.detachedVerify(
      nd.NanoHelpers.stringToBytesUtf8(message),
      nd.NanoHelpers.hexToBytes(signature),
      nd.NanoHelpers.stringToBytesUtf8(publicKey),
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

  static String signBlock(String hash, String privateKey) {
    return nd.NanoSignatures.signBlock(hash, privateKey);
  }
}

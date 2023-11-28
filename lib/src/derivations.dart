import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:libcrypto/libcrypto.dart';
import 'package:nanodart/nanodart.dart';
import 'package:decimal/decimal.dart';

enum NanoBasedCurrency { NANO, BANANO, NYANO }

enum NanoDerivationType { STANDARD, HD }

class NanoDerivations {
  // standard:
  static String standardSeedToPrivate(String seed, {int index = 0}) {
    return NanoKeys.seedToPrivate(seed, index);
  }

  static String standardSeedToAddress(String seed, {int index = 0}) {
    return NanoAccounts.createAccount(NanoAccountType.NANO,
        privateKeyToPublic(standardSeedToPrivate(seed, index: index)));
  }

  static String standardSeedToMnemonic(String seed) {
    return NanoMnemomics.seedToMnemonic(seed).join(' ');
  }

  static Future<String> standardMnemonicToSeed(String mnemonic) async {
    return NanoMnemomics.mnemonicListToSeed(mnemonic.split(' '));
  }

  static String addressToPublicKey(String publicAddress) {
    return NanoAccounts.extractPublicKey(publicAddress);
  }

  // universal:

  static String privateKeyToPublic(String privateKey) {
    // return NanoHelpers.byteToHex(Ed25519Blake2b.getPubkey(NanoHelpers.hexToBytes(privateKey))!);
    return NanoKeys.createPublicKey(privateKey);
  }

  static String privateKeyToAddress(String privateKey,
      {NanoBasedCurrency currency = NanoBasedCurrency.NANO}) {
    int accountType = currency == NanoBasedCurrency.NANO
        ? NanoAccountType.NANO
        : NanoAccountType.BANANO;
    return NanoAccounts.createAccount(
        accountType, privateKeyToPublic(privateKey));
  }

  static String publicKeyToAddress(String publicKey,
      {NanoBasedCurrency currency = NanoBasedCurrency.NANO}) {
    final int accountType = currency == NanoBasedCurrency.NANO
        ? NanoAccountType.NANO
        : NanoAccountType.BANANO;
    return NanoAccounts.createAccount(accountType, publicKey);
  }

  // standard + hd:
  static bool isValidHexFormSeed(String seed) {
    // Ensure seed is 64 or 128 characters long
    if ((seed.length != 64 && seed.length != 128)) {
      return false;
    }
    // Ensure seed only contains hex characters, 0-9;A-F
    return NanoHelpers.isHexString(seed);
  }

  // // hd:
  static Future<String> hdMnemonicListToSeed(List<String> words) async {
    // if (words.length != 24) {
    //   throw Exception('Expected a 24-word list, got a ${words.length} list');
    // }
    final Uint8List salt = Uint8List.fromList(utf8.encode('mnemonic'));
    final Pbkdf2 hasher = Pbkdf2(iterations: 2048);
    final String seed = await hasher.sha512(words.join(' '), salt);
    return seed;
  }

  static Future<String> hdSeedToPrivate(String seed,
      {int index = 0,
      NanoBasedCurrency currency = NanoBasedCurrency.NANO}) async {
    List<int> seedBytes = hex.decode(seed);
    KeyData data =
        await ED25519_HD_KEY.derivePath("m/44'/165'/$index'", seedBytes);
    return hex.encode(data.key);
  }

  static Future<String> hdSeedToAddress(String seed,
      {int index = 0,
      NanoBasedCurrency currency = NanoBasedCurrency.NANO}) async {
    final int accountType = currency == NanoBasedCurrency.NANO
        ? NanoAccountType.NANO
        : NanoAccountType.BANANO;
    return NanoAccounts.createAccount(
        accountType,
        privateKeyToPublic(
            await hdSeedToPrivate(seed, index: index, currency: currency)));
  }

  static Future<String> universalSeedToAddress(String seed,
      {int index = 0, NanoDerivationType type = NanoDerivationType.STANDARD}) {
    switch (type) {
      case NanoDerivationType.STANDARD:
        return Future<String>.value(standardSeedToAddress(seed, index: index));
      case NanoDerivationType.HD:
        return hdSeedToAddress(seed, index: index);
      default:
        throw Exception('Unknown seed type');
    }
  }

  static Future<String> universalSeedToPrivate(String seed,
      {int index = 0, NanoDerivationType type = NanoDerivationType.STANDARD}) {
    switch (type) {
      case NanoDerivationType.STANDARD:
        return Future<String>.value(standardSeedToPrivate(seed, index: index));
      case NanoDerivationType.HD:
        return hdSeedToPrivate(seed, index: index);
      default:
        throw Exception('Unknown seed type');
    }
  }

  static bool isValidBip39Seed(String seed) {
    // Ensure seed is 128 characters long
    if (seed.length != 128) {
      return false;
    }
    // Ensure seed only contains hex characters, 0-9;A-F
    return NanoHelpers.isHexString(seed);
  }
}

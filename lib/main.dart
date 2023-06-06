import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutterchain/flutterchain_lib.dart';
import 'package:flutterchain/flutterchain_lib/constants/core/supported_blockchains.dart';
import 'package:flutterchain/flutterchain_lib/formaters/chains/near_formater.dart';
import 'package:flutterchain/flutterchain_lib/models/chains/near/near_blockchain_data.dart';
import 'package:flutterchain/flutterchain_lib/models/chains/near/near_blockchain_smart_contract_arguments.dart';
import 'package:flutterchain/flutterchain_lib/models/core/wallet.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:flutterchain/flutterchain_lib/services/core/lib_initialization_service.dart';
import 'package:rxdart/rxdart.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFlutterChainLib();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final BehaviorSubject<AppState> stateStream = BehaviorSubject<AppState>();
  final FlutterChainLibrary library = FlutterChainLibrary.defaultInstance();

  Future<void> createWallet() async {
    final wallet = await library.createWalletWithGeneratedMnemonic(
        walletName: "Test + ${DateTime.now().toString()}");
    stateStream.add(AppState(walletCreatingResult: wallet));
  }

  Future<void> transferTokens() async {
    final wallet = stateStream.value.walletCreatingResult;
    final nearService = library.blockchainService
        .blockchainServices[BlockChains.near] as NearBlockChainService;

    final blockchainData = wallet.blockchainsData![BlockChains.near]!.first;
    final res = await nearService.sendTransferNativeCoin(
      'vladddddd.testnet',
      blockchainData.publicKey,
      NearFormatter.nearToYoctoNear('1'),
      blockchainData.privateKey,
      blockchainData.publicKey,
    );
    stateStream.add(stateStream.value.copyWith(transferResult: res.status));
  }

  Future<void> callSmartContract() async {
    final wallet = stateStream.value.walletCreatingResult;
    final nearService = library.blockchainService
        .blockchainServices[BlockChains.near] as NearBlockChainService;

    final blockchainData = wallet.blockchainsData![BlockChains.near]!.first;
    final res = await nearService.callSmartContractFunction(
      'dev-1679756367837-29230485683009',
      blockchainData.publicKey,
      blockchainData.privateKey,
      blockchainData.publicKey,
      NearBlockChainSmartContractArguments(
        method: 'get_greeting',
        // method: 'set_greeting',
        // args: {"message": "Hello From Flutter to Near Example"},
        args: {},

        transferAmount: NearFormatter.nearToYoctoNear('0'),
      ),
    );
    stateStream.add(stateStream.value.copyWith(
        smartContractCallResult:
            "Result of SM call -> ${res.data['success']}"));
  }

  Future<void> addKey() async {
    final wallet = stateStream.value.walletCreatingResult;
    final nearService = library.blockchainService
        .blockchainServices[BlockChains.near] as NearBlockChainService;

    final blockchainData = wallet.blockchainsData![BlockChains.near]!.first;
    final randomWallet =
        await library.blockchainService.generateNewWallet(walletName: "Random");
    const derivationPathRandom = DerivationPath(
      accountNumber: '0',
      change: '0',
      address: '0',
      coinType: '397',
      purpose: '44',
    );
    final randomBlockChainData =
        await nearService.getBlockChainDataByDerivationPath(
            derivationPath: derivationPathRandom,
            mnemonic: randomWallet.mnemonic,
            passphrase: '');
    log("randomBlockChainData publicKey ${randomBlockChainData.publicKey}");
    final res = await nearService.addKey(
      allowance: NearFormatter.nearToYoctoNear('1'),
      derivationPathOfNewGeneratedAccount: derivationPathRandom,
      fromAddress: blockchainData.publicKey,
      methodNames: [
        'set_greeting',
        'get_greeting',
      ],
      mnemonic: randomWallet.mnemonic,
      permission: 'functionCall',
      privateKey: blockchainData.privateKey,
      publicKey: blockchainData.publicKey,
      smartContractId: 'dev-1679756367837-29230485683009',
    );
    stateStream.add(
      stateStream.value.copyWith(
        addKeyResult: res.status,
        publicKeyOfNewAddedKey: randomBlockChainData.publicKey,
      ),
    );
  }

  Future<void> deleteKey() async {
    final wallet = stateStream.value.walletCreatingResult;
    final nearService = library.blockchainService
        .blockchainServices[BlockChains.near] as NearBlockChainService;

    final blockchainData =
        wallet.blockchainsData![BlockChains.near]!.first as NearBlockChainData;

    final res = await nearService.deleteKey(
      accountId: blockchainData.accountId ?? blockchainData.publicKey,
      privateKey: blockchainData.privateKey,
      publicKey: blockchainData.publicKey,
      deletedPublicKey: stateStream.value.publicKeyOfNewAddedKey,
    );
    stateStream.add(stateStream.value.copyWith(deleteKeyResult: res.status));
  }

  Future<void> exportKey() async {
    final wallet = stateStream.value.walletCreatingResult;
    final nearService = library.blockchainService
        .blockchainServices[BlockChains.near] as NearBlockChainService;

    final blockchainData = wallet.blockchainsData![BlockChains.near]!.first;

    final secretKey = await nearService.exportPrivateKeyToTheNearApiJsFormat(
      currentBlockchainData: blockchainData,
    );
    stateStream.add(stateStream.value.copyWith(exportKeyResult: secretKey));
  }

  Future<void> importKey() async {
    final nearService = library.blockchainService
        .blockchainServices[BlockChains.near] as NearBlockChainService;

    final privateKeyFlutterChainFormat =
        await nearService.getPrivateKeyFromSecretKeyFromNearApiJSFormat(
      stateStream.value.exportKeyResult.toString().split(":").last,
    );
    final publicKeyFlutterChainFormat =
        await nearService.getPublicKeyFromSecretKeyFromNearApiJSFormat(
      stateStream.value.exportKeyResult.toString().split(":").last,
    );

    stateStream.add(stateStream.value.copyWith(
        importKeyResult:
            "privateKeyFlutterChainFormat -> $privateKeyFlutterChainFormat \n  publicKeyFlutterChainFormat -> $publicKeyFlutterChainFormat "));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: StreamBuilder<AppState>(
          stream: stateStream,
          builder: (context, snapshot) {
            final currentState = snapshot.data;
            return Center(
              child: ListView(
                children: <Widget>[
                  ActionCard(
                    title: '1. Create Account',
                    onPressed: createWallet,
                    result: currentState?.walletCreatingResult.toString() ?? '',
                  ),
                  ActionCard(
                    title: '2. Transfer Tokens',
                    onPressed: transferTokens,
                    result: currentState?.transferResult.toString() ?? '',
                  ),
                  ActionCard(
                    title: '3. Call Smart Contract',
                    onPressed: callSmartContract,
                    result:
                        currentState?.smartContractCallResult.toString() ?? '',
                  ),
                  ActionCard(
                    title: '4. Add Key',
                    onPressed: addKey,
                    result: currentState?.addKeyResult.toString() ?? '',
                  ),
                  ActionCard(
                    title: '5. Delete Key',
                    onPressed: deleteKey,
                    result: currentState?.deleteKeyResult.toString() ?? '',
                  ),
                  ActionCard(
                    title: '6. Export from the Near-API-JS',
                    onPressed: exportKey,
                    result: currentState?.exportKeyResult.toString() ?? '',
                  ),
                  ActionCard(
                    title: '7. Import from the Near-API-JS',
                    onPressed: importKey,
                    result: currentState?.importKeyResult.toString() ?? '',
                  ),
                ],
              ),
            );
          }),
    );
  }
}

class AppState {
  final Wallet walletCreatingResult;
  final dynamic transferResult;
  final dynamic smartContractCallResult;
  final dynamic addKeyResult;
  final dynamic deleteKeyResult;
  final dynamic importKeyResult;
  final dynamic exportKeyResult;
  final dynamic publicKeyOfNewAddedKey;

  AppState({
    required this.walletCreatingResult,
    this.transferResult,
    this.smartContractCallResult,
    this.addKeyResult,
    this.deleteKeyResult,
    this.exportKeyResult,
    this.importKeyResult,
    this.publicKeyOfNewAddedKey,
  });
  AppState copyWith({
    Wallet? walletCreatingResult,
    dynamic transferResult,
    dynamic smartContractCallResult,
    dynamic addKeyResult,
    dynamic deleteKeyResult,
    dynamic importKeyResult,
    dynamic exportKeyResult,
    dynamic publicKeyOfNewAddedKey,
  }) {
    return AppState(
      walletCreatingResult: walletCreatingResult ?? this.walletCreatingResult,
      transferResult: transferResult ?? this.transferResult,
      smartContractCallResult:
          smartContractCallResult ?? this.smartContractCallResult,
      addKeyResult: addKeyResult ?? this.addKeyResult,
      deleteKeyResult: deleteKeyResult ?? this.deleteKeyResult,
      importKeyResult: importKeyResult ?? this.importKeyResult,
      exportKeyResult: exportKeyResult ?? this.exportKeyResult,
      publicKeyOfNewAddedKey:
          publicKeyOfNewAddedKey ?? this.publicKeyOfNewAddedKey,
    );
  }
}

class ActionCard extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final String result;

  ActionCard({
    required this.title,
    required this.onPressed,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontSize: 20),
          ),
          ElevatedButton(
            onPressed: onPressed,
            child: const Text("Execute"),
          ),
          SelectableText(result),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutterchain/flutterchain_lib.dart';
import 'package:flutterchain/flutterchain_lib/constants/core/supported_blockchains.dart';
import 'package:flutterchain/flutterchain_lib/formaters/chains/near_formater.dart';
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

  Future<void> createWallet() async {
    final wallet = await FlutterChainLibrary.defaultInstance()
        .createWalletWithGeneratedMnemonic(
            walletName: "Test + ${DateTime.now().toString()}");
    stateStream.add(AppState(walletCreatingResult: wallet));
  }

  Future<void> transferTokens() async {
    final wallet = stateStream.value.walletCreatingResult;
    final nearService = FlutterChainLibrary.defaultInstance()
        .blockchainService
        .blockchainServices[BlockChains.near] as NearBlockChainService;

    final blockchainData = wallet.blockchainsData![BlockChains.near]!.first;
    final res = await nearService.sendTransferNativeCoin(
      'vladddddd.testnet',
      blockchainData.publicKey,
      NearFormatter.nearToYoctoNear('1'),
      blockchainData.privateKey,
      blockchainData.publicKey,
    );
    stateStream.add(stateStream.value.copyWith(transferResult: res));
  }

  Future<void> callSmartContract() async {
    final wallet = stateStream.value.walletCreatingResult;
    final nearService = FlutterChainLibrary.defaultInstance()
        .blockchainService
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
    stateStream.add(stateStream.value.copyWith(smartContractCallResult: res));
  }

  Future<void> addKey() async {
    final wallet = stateStream.value.walletCreatingResult;
    final nearService = FlutterChainLibrary.defaultInstance()
        .blockchainService
        .blockchainServices[BlockChains.near] as NearBlockChainService;

    final blockchainData = wallet.blockchainsData![BlockChains.near]!.first;
    final res = await nearService.addKey(
      allowance: NearFormatter.nearToYoctoNear('1'),
      derivationPathOfNewGeneratedAccount: const DerivationPath(
        accountNumber: '0',
        change: '0',
        address: '0',
        coinType: '397',
        purpose: '44',
      ),
      fromAddress: blockchainData.publicKey,
      methodNames: [],
      mnemonic: wallet.mnemonic,
      permission: '',
      privateKey: blockchainData.privateKey,
      publicKey: blockchainData.publicKey,
      smartContractId: 'dev-1679756367837-29230485683009',
    );
    stateStream.add(stateStream.value.copyWith(addKeyResult: res));
  }

  Future<void> deleteKey() async {
    final wallet = stateStream.value.walletCreatingResult;
    final nearService = FlutterChainLibrary.defaultInstance()
        .blockchainService
        .blockchainServices[BlockChains.near] as NearBlockChainService;

    final blockchainData = wallet.blockchainsData![BlockChains.near]!.first;

    final res = await nearService.deleteKey(
      fromAdress: 'your_added_key',
      privateKey: blockchainData.privateKey,
      publicKey: blockchainData.publicKey,
    );
    stateStream.add(stateStream.value.copyWith(deleteKeyResult: res));
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
                    result: currentState?.transferResult.toString() ?? '',
                  ),
                  ActionCard(
                    title: '4. Add Key',
                    onPressed: addKey,
                    result: currentState?.transferResult.toString() ?? '',
                  ),
                  ActionCard(
                    title: '5. Delete Key',
                    onPressed: deleteKey,
                    result: currentState?.transferResult.toString() ?? '',
                  ),
                  ActionCard(
                    title: '6. Import from the Near-API-JS',
                    onPressed: () {},
                    result: currentState?.transferResult.toString() ?? '',
                  ),
                  ActionCard(
                    title: '7. Export from the Near-API-JS',
                    onPressed: () {},
                    result: currentState?.transferResult.toString() ?? '',
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

  AppState({
    required this.walletCreatingResult,
    this.transferResult,
    this.smartContractCallResult,
    this.addKeyResult,
    this.deleteKeyResult,
  });
  AppState copyWith({
    Wallet? walletCreatingResult,
    dynamic transferResult,
    dynamic smartContractCallResult,
    dynamic addKeyResult,
    dynamic deleteKeyResult,
  }) {
    return AppState(
      walletCreatingResult: walletCreatingResult ?? this.walletCreatingResult,
      transferResult: transferResult ?? this.transferResult,
      smartContractCallResult:
          smartContractCallResult ?? this.smartContractCallResult,
      addKeyResult: addKeyResult ?? this.addKeyResult,
      deleteKeyResult: deleteKeyResult ?? this.deleteKeyResult,
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
          Text(title, style: TextStyle(fontSize: 20)),
          ElevatedButton(
            child: Text(title),
            onPressed: onPressed,
          ),
          SelectableText(result),
        ],
      ),
    );
  }
}

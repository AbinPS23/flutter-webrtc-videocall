import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:vid_call/snack_msg.dart';

import '../signaling.dart';



typedef ExecuteCallback = void Function();
typedef ExecuteFutureCallback = Future<void> Function();

//main method 
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const App());
}

//material app
class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home:  Home(),
    );
  }
}

//home page where we can make a call
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  //creating random local user name
  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static final _rnd = Random();

  static String getRandomString(int length) => String.fromCharCodes(Iterable.generate(length, (index) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  //passing local user name to signalling
  final signaling = Signaling(localDisplayName: getRandomString(20));

  //local renderer
  final localRenderer = RTCVideoRenderer();
  //video renderer
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  final Map<String, bool?> remoteRenderersLoading = {};

  //roomId
  String roomId = ''; //initially empty

  //local render state
  bool localRenderOk = false;
  //error state
  bool error = false;

  //*initState
  @override
  void initState() {
    super.initState();

    //adding local stream to local renderer and update local render state
    signaling.onAddLocalStream = ((peerUuid, displayName, stream) {
      localRenderer.srcObject = stream; //adding stream to local renderer
      //stream not null then local render state updated
      localRenderOk = stream!=null; //true or false
      setState(() {
        
      });
    });

    //adding remote stream to remote renderer and update remote render state
    signaling.onAddRemoteStream =(peerUuid, displayName, stream) async{
      final remoteRenderer = RTCVideoRenderer(); // creating instance 
      await remoteRenderer.initialize(); // initializing remote renderer
      remoteRenderer.srcObject = stream; //adding tracks to remoteRenderer 

      setState(() {
        remoteRenderers[peerUuid] = remoteRenderer; //updating remoteRenderers
      });

      //remove remote stream
      signaling.onRemoveRemoteStream = (peerUuid, displayName) {
        if(remoteRenderers.containsKey(peerUuid)){
          remoteRenderers[peerUuid]!.srcObject = null; //update remote stream as null
          remoteRenderers[peerUuid]!.dispose(); //dispose remote renderers

          setState(() {
            remoteRenderers.remove(peerUuid);  //?remove remote renderers
            remoteRenderersLoading.remove(peerUuid); //?remove remote renderers loading
          });

        }
      };

      //connection connected state
      signaling.onConnectionConnected =(peerUuid, displayName) {
        setState(() {
          remoteRenderersLoading[peerUuid] = false;
        });
      };

      //connection loading state
      signaling.onConnectionLoading =(peerUuid, displayName) {
        setState(() {
          remoteRenderersLoading[peerUuid] = true;
        });
      };

      //connection error state
      signaling.onConnectionError =(peerUuid, displayName) {
        //updating errror state
        error = true;
        //show error message to user
        SnackMsg.showError(context, 'Connection Failed with $displayName'); //!snackbar connection error
      };

      signaling.onGenericError = (errorText) {
        //updating error state
        error = true;
        //show eror message to user
        SnackMsg.showError(context, errorText);

      };

      //todo initialize camera
      //todo request cam and mic permissions
      //initCamera();
      
    };
  }


  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

  @override
  void dispose() {
    localRenderer.dispose();
    //todo dispose remote renderers
    //disposeRemoteRenderers();
    super.dispose();
  }
}
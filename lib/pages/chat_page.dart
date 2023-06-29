// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:chat/components/chat_bubble.dart';
import 'package:chat/components/my_textfield.dart';
import 'package:chat/services/chat/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    Key? key,
    required this.receiverEmail,
    required this.receiverUserId,
  }) : super(key: key);
  final String receiverEmail;
  final String receiverUserId;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
          widget.receiverUserId, _messageController.text);
      _messageController.clear();
    }
  }

  late Widget streamBuilder;
  @override
  void initState() {
    //build message list
    streamBuilder = StreamBuilder(
      stream: _chatService.getMessage(
        widget.receiverUserId,
        _firebaseAuth.currentUser!.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error +${snapshot.error}'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Text('Loading...'),
          );
        }
        return SingleChildScrollView(
          reverse: true,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: snapshot.data!.docs
                .map((doc) => _builderMessageItem(doc))
                .toList(),
          ),
        );
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.grey),
          backgroundColor: Colors.grey[900],
          title: Text(
            widget.receiverEmail,
            style: const TextStyle(color: Colors.grey, fontSize: 20),
          ),
        ),
        body: Column(
          children: [
            //message
            Expanded(
              child: streamBuilder,
            ),
            //user input
            _builderMessageInput(),
            const SizedBox(height: 10),
          ],
        ),
      );

  //build message item
  Widget _builderMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    //align message to right if sender is currant user,otherwise to the lift
    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment:
              (data['senderId'] == _firebaseAuth.currentUser!.uid)
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          mainAxisAlignment:
              (data['senderId'] == _firebaseAuth.currentUser!.uid)
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
          children: [
            Text(
              data['senderEmail'],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            ChatBubble(
              message: data['message'],
              color: (data['senderId'] == _firebaseAuth.currentUser!.uid)
                  ? Colors.grey[900]!
                  : Colors.green,
            )
          ],
        ),
      ),
    );
  }

  //build message input
  Widget _builderMessageInput() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Row(
          children: [
            Expanded(
              child: MyTextField(
                controller: _messageController,
                hintText: 'Enter message...',
                obscureText: false,
              ),
            ),
            IconButton(
              onPressed: sendMessage,
              icon: const Icon(Icons.send_outlined),
            ),
          ],
        ),
      );
}

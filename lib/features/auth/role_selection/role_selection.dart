// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:survey_camp/core/models/user_role_model.dart';
// import 'package:survey_camp/core/providers/auth_provider.dart';

// class RoleSelectionPage extends ConsumerWidget {
//   const RoleSelectionPage({super.key});

//   Future<void> _selectRole(
//       BuildContext context, WidgetRef ref, UserRole role) async {
//     try {
//       await ref.read(authProvider.notifier).setUserRole(role);
//       if (context.mounted) {
//         Navigator.pushReplacementNamed(context, '/');
//       }
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString())),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Select Your Role'),
//         automaticallyImplyLeading: false,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'Choose your role to continue',
//               style: TextStyle(fontSize: 20),
//             ),
//             const SizedBox(height: 32),
//             for (final role in UserRole.values) ...[
//               ElevatedButton(
//                 onPressed: () => _selectRole(context, ref, role),
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 48,
//                     vertical: 16,
//                   ),
//                 ),
//                 child: Text(role.displayName),
//               ),
//               const SizedBox(height: 16),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

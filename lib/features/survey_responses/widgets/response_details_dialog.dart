import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/survey_response_model.dart';
import '../services/survey_response_service.dart';

class ResponseDetailsDialog extends StatefulWidget {
  final SurveyResponse response;
  final SurveyResponseService surveyResponseService;

  const ResponseDetailsDialog({
    Key? key,
    required this.response,
    required this.surveyResponseService,
  }) : super(key: key);

  @override
  State<ResponseDetailsDialog> createState() => _ResponseDetailsDialogState();
}

class _ResponseDetailsDialogState extends State<ResponseDetailsDialog> {
  late bool isValid;
  bool _isXpGiven = false;
  double _pointsPercentage = 0.0;
  int _userPoints = 0;
  int _totalPossiblePoints = 0;
  int _userxpPoints = 0;
  

  @override
  void initState() {
    super.initState();
    isValid = widget.response.isValid;
    _checkXpStatus();
    _calculatePointsPercentage();
    _userxpPoints = widget.response.responses.length * 2;
  }

Future<void> _calculatePointsPercentage() async {
  try {
    // Get total possible points from users collection
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.response.userId);

    final userDoc = await userRef.get();
    
    if (userDoc.exists) {
      // Get Userpoints from the survey response
      _userPoints = widget.response.toMap()['Userpoints'] ?? 0;
      _totalPossiblePoints = userDoc.data()?['totalPoints'] ?? 0;
      
      // Calculate percentage based on total points
      if (_totalPossiblePoints > 0) {
        setState(() {
          _pointsPercentage = (_userPoints / _totalPossiblePoints) * 100;
        });
      }
    }
  } catch (e) {
    print('Error calculating points percentage: $e');
  }
}

  Future<void> _checkXpStatus() async {
    final hasXp = await widget.surveyResponseService.checkIfXpGiven(widget.response.id);
    setState(() {
      _isXpGiven = hasXp;
    });
  }

  void _toggleIsValid() async {
    setState(() {
      isValid = !isValid;
    });

    try {
      await widget.surveyResponseService
          .updateIsValidStatus(widget.response.id, isValid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update validity: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Response Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Submitted: ${widget.surveyResponseService.formatDateTime(widget.response.submittedAt)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _pointsPercentage < 50 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Points Progress:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _pointsPercentage < 50 
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                Text(
                  '${_pointsPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _pointsPercentage < 50 
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Points: $_userPoints / $_totalPossiblePoints',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(widget.response.responses.length, (index) {
                final questionResponse = widget.response.responses[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${questionResponse.question}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87),
                          children: [
                            const TextSpan(
                              text: 'Answer: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: questionResponse.answer.toString(),
                            ),
                          ],
                        ),
                      ),
                      if (questionResponse.timeSpent != null) ...[
                        const SizedBox(height: 4),
                        // Text(
                        //   'Time spent: ${widget.surveyResponseService.formatDuration(questionResponse.timeSpent!)}',
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     color: Colors.grey[600],
                        //   ),
                        // ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _isXpGiven ? Colors.grey : Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _isXpGiven 
                    ? 'XP Already Given' 
                    : 'Give +$_userxpPoints XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _isXpGiven 
                  ? null 
                  : () async {
                      try {
                        await widget.surveyResponseService
                            .addXpToUser(widget.response.userId, _userxpPoints);

                        // Mark XP as given
                        await widget.surveyResponseService
                            .markXpAsGiven(widget.response.id);

                        setState(() {
                          _isXpGiven = true;
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added $_userxpPoints XP points!'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add XP: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ],
    );
  }
}

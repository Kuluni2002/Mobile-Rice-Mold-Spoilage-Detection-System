import 'package:flutter/material.dart';

import '../../../core/errors/analysis_failure.dart';
import '../../../core/utils/permission_handler.dart';

Future<void> showFailureDialog(
  BuildContext context,
  AnalysisFailure failure, {
  VoidCallback? onRetry,
  VoidCallback? onChooseAnotherPhoto,
}) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(failure.title),
      content: Text('${failure.message}\n\n${failure.hint}'),
      actions: [
        if (onChooseAnotherPhoto != null)
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onChooseAnotherPhoto();
            },
            child: const Text('Choose another photo'),
          ),
        if (failure.canOpenSettings)
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              PermissionHandlerUtil.openAppSettings();
            },
            child: const Text('Open settings'),
          ),
        if (onRetry != null)
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onRetry();
            },
            child: const Text('Try again'),
          )
        else
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
      ],
    ),
  );
}

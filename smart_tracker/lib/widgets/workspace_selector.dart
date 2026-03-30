import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/workspace_store.dart';
import '../theme/app_theme.dart';
import 'section_card.dart';

class WorkspaceSelector extends StatelessWidget {
  const WorkspaceSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceStore>(
      builder: (context, store, _) {
        if (!store.isLoaded) {
          return const SizedBox.shrink();
        }
        final selected = store.selectedWorkspace;
        if (selected == null) return const SizedBox.shrink();

        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workspace',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selected.id,
                items: store.workspaces
                    .map((workspace) => DropdownMenuItem(value: workspace.id, child: Text(workspace.name)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    store.selectWorkspace(value);
                  }
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
        );
      },
    );
  }
}

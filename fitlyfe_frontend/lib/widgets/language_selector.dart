import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/l10n/generated/app_localizations.dart';
import '../providers/locale_provider.dart';

class LanguageSelector extends StatelessWidget {
  final bool isGrid;

  const LanguageSelector({super.key, this.isGrid = false});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    final locales = LocaleProvider.supportedLocales;
    final currentLocale = provider.locale;

    if (isGrid) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: locales.length,
        itemBuilder: (context, index) {
          final locale = locales[index];
          final isSelected = currentLocale?.languageCode == locale.languageCode;
          return _buildGridItem(context, locale, isSelected, provider);
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      // First row follows the phone's language
      itemCount: locales.length + 1,
      separatorBuilder: (ctx, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildListItem(context, null, currentLocale == null, provider);
        }
        final locale = locales[index - 1];
        final isSelected = currentLocale?.languageCode == locale.languageCode;
        return _buildListItem(context, locale, isSelected, provider);
      },
    );
  }

  Widget _buildListItem(
    BuildContext context,
    Locale? locale,
    bool isSelected,
    LocaleProvider provider,
  ) {
    return ListTile(
      onTap: () {
        provider.setLocale(locale);
      },
      title: Text(
        locale == null
            ? AppLocalizations.of(context).languageSystemDefault
            : LocaleProvider.nativeName(locale),
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
          : null,
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    Locale locale,
    bool isSelected,
    LocaleProvider provider,
  ) {
    return InkWell(
      onTap: () => provider.setLocale(locale),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                LocaleProvider.nativeName(locale),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

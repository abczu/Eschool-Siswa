import 'package:flutter/material.dart';

class SchoolSelectorDialog extends StatelessWidget {
  final List<Map<String, dynamic>> schools;

  const SchoolSelectorDialog({
    Key? key,
    required this.schools,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFFE63946);
    final Color textDark = const Color(0xFF1D3557);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school_rounded,
                  color: primaryRed,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Pilih Sekolah",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Akun Anda terdaftar di beberapa sekolah. Silakan pilih salah satu untuk melanjutkan.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: schools.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final school = schools[index];
                  final name = school['name'] ?? 'Sekolah';
                  final code = school['code'] ?? '';

                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop(school);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey.shade50.withValues(alpha: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryRed.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.school_outlined,
                              color: primaryRed,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textDark,
                                  ),
                                ),
                                if (code.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Kode: $code",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

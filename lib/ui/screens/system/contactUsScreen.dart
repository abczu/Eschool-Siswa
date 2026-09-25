
import 'package:eschool/cubits/system/appSettingsCubit.dart';
import 'package:eschool/data/repositories/system/systemInfoRepository.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();

  static Widget routeInstance() {
    return BlocProvider<AppSettingsCubit>(
      create: (context) => AppSettingsCubit(SystemRepository()),
      child: const ContactUsScreen(),
    );
  }
}

class _ContactUsScreenState extends State<ContactUsScreen>
    with SingleTickerProviderStateMixin {
  final String contactUsType = "contact_us";
  late AnimationController _controller;
  String? cachedData;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    Future.delayed(Duration.zero, () {
      context.read<AppSettingsCubit>().fetchAppSettings(type: contactUsType);
    });
    _loadCachedData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cachedData = prefs.getString("contact_us");
    });
  }

  Widget _buildAppBar() {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarSmallerHeightPercentage,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              left: 10,
              top: -2,
              child: const CustomBackButton(),
            ),
            Text(
              Utils.getTranslatedLabel(contactUsKey),
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontSize: Utils.screenTitleFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: BlocConsumer<AppSettingsCubit, AppSettingsState>(
        listener: (context, state) {
          if (state is AppSettingsFetchFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage)),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Animated Background Pattern
              AnimatedPositioned(
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height,
                child: AnimatedOpacity(
                  duration: const Duration(seconds: 1),
                  opacity: 0.1,
                  child: CustomPaint(
                    painter: BackgroundPainter(
                      color: primaryColor,
                    ),
                  ),
                ),
              ),

              // Main Content
              SingleChildScrollView(
                padding: EdgeInsets.only(
                    top: Utils.getScrollViewTopPadding(
                        context: context,
                        appBarHeightPercentage:
                            Utils.appBarSmallerHeightPercentage)),
                child: Column(
                  children: [
                    // Header Section
// Import the necessary package at the top (already imported)
// import 'package:animate_do/animate_do.dart';

// Inside the build method, replace the header section with this:
// Header Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.9),
                            primaryColor.withValues(alpha: 1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animated typing text
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              String text =
                                  Utils.getTranslatedLabel(howWeCanHelpKey);
                              int charactersToShow =
                                  (text.length * _controller.value).round();
                              String displayedText =
                                  text.substring(0, charactersToShow);

                              return Text(
                                displayedText,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            Utils.getTranslatedLabel(howWeCanHelpDescKey),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contact Cards
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Extract contact info from appSettingsResult if available
                          Builder(
                            builder: (context) {
                              String email = '';
                              String phone = '';
                              String address = '';

                              if (state is AppSettingsFetchSuccess) {
                                final result = state.appSettingsResult;
                                
                                // Convert HTML to plain text with newlines
                                String plainText = result
                                    .replaceAll(RegExp(r'<br[^>]*>', caseSensitive: false), '\n')
                                    .replaceAll(RegExp(r'</p>|</div>|</h[1-6]>', caseSensitive: false), '\n')
                                    .replaceAll(RegExp(r'<[^>]+>'), '')
                                    .replaceAll(RegExp(r'\n+'), '\n')
                                    .trim();

                                // Extract data line by line
                                List<String> lines = plainText
                                    .split('\n')
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList();

                                for (int i = 0; i < lines.length; i++) {
                                  String line = lines[i];
                                  
                                  // Extract Email
                                  if (email.isEmpty) {
                                    final emailMatch = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').firstMatch(line);
                                    if (emailMatch != null) email = emailMatch.group(0)!;
                                  }
                                  
                                  // Extract Phone (+62 or 08 followed by numbers, spaces, dashes)
                                  if (phone.isEmpty) {
                                    final phoneMatch = RegExp(r'(?:\+62|08)[0-9\-\s]{8,20}').firstMatch(line);
                                    if (phoneMatch != null) {
                                      // Clean up the phone string
                                      phone = phoneMatch.group(0)!.trim();
                                    }
                                  }
                                  
                                  // Extract Address
                                  if (address.isEmpty && line.toLowerCase().contains('alamat') && i + 1 < lines.length) {
                                    // Take the next line as address
                                    address = lines[i + 1];
                                  }
                                }
                              }

                              return Column(
                                children: [
                                  _buildContactCard(
                                    Icons.email_rounded,
                                    Utils.getTranslatedLabel(sendEmailKey),
                                    email,
                                    primaryColor: primaryColor,
                                    onTap: () async {
                                      if (email.isNotEmpty) {
                                        final Uri emailUri = Uri(
                                          scheme: 'mailto',
                                          path: email,
                                        );
                                        try {
                                          await url_launcher.launchUrl(
                                            emailUri,
                                            mode: url_launcher
                                                .LaunchMode.externalApplication,
                                          );
                                        } catch (e) {
                                          debugPrint('Could not launch email: $e');
                                        }
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildContactCard(
                                    Icons.phone_rounded,
                                    Utils.getTranslatedLabel(contactUsKey),
                                    phone,
                                    primaryColor: primaryColor,
                                    onTap: () async {
                                      if (phone.isNotEmpty) {
                                        final Uri phoneUri = Uri(
                                          scheme: 'tel',
                                          path: phone,
                                        );
                                        try {
                                          await url_launcher.launchUrl(
                                            phoneUri,
                                            mode: url_launcher
                                                .LaunchMode.externalApplication,
                                          );
                                        } catch (e) {
                                          debugPrint('Could not launch phone: $e');
                                        }
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildContactCard(
                                    Icons.location_on_rounded,
                                    Utils.getTranslatedLabel(visitUsKey),
                                    address,
                                    primaryColor: primaryColor,
                                    onTap: () async {
                                      if (address.isNotEmpty) {
                                        // Use Google Maps URL for better compatibility
                                        final Uri mapUri = Uri.parse(
                                          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
                                        );
                                        try {
                                          await url_launcher.launchUrl(
                                            mapUri,
                                            mode: url_launcher
                                                .LaunchMode.externalApplication,
                                          );
                                        } catch (e) {
                                          debugPrint('Could not launch map: $e');
                                        }
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              _buildAppBar()
            ],
          );
        },
      ),
    );
  }

  Widget _buildContactCard(
    IconData icon,
    String title,
    String content, {
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return FadeInUp(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          splashColor: primaryColor.withValues(alpha: 0.1),
          highlightColor: primaryColor.withValues(alpha: 0.05),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 30, color: primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (content.isNotEmpty)
                        Text(
                          content,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final Color color;

  BackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < size.width; i += 20) {
      for (var j = 0; j < size.height; j += 20) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 윈도우 매니저 초기화
  await windowManager.ensureInitialized();
  
  // 오버플로우가 발생하지 않는 최소 크기 계산
  // 컨텐츠 기반으로 계산된 최소 크기
  const double minContentWidth = 450; // 더 컴팩트한 사이즈
  const double minContentHeight = 580; // 상단(200) + 로그인 섹션(320) + 여백(60)
  
  // 적당한 비율 적용 - 세로가 더 길지만 너무 길지 않게
  const double windowWidth = 480;
  const double windowHeight = 650; // 황금비율보다 짧게 조정
  
  WindowOptions windowOptions = WindowOptions(
    size: Size(windowWidth, windowHeight),
    minimumSize: Size(windowWidth, windowHeight),
    maximumSize: Size(windowWidth, windowHeight),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
    title: 'SIGMA - Smart Interactive Gesture Management Assistant',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  runApp(const SigmaApp());
}

class SigmaApp extends StatelessWidget {
  const SigmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGMA - Smart Interactive Gesture Management Assistant',
      theme: ThemeData(
        fontFamily: GoogleFonts.roboto().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4285F4),
          brightness: Brightness.light,
        ),
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Figma Node ID: 1-5 (로그인 화면)
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 사용 가능한 공간에 따라 동적으로 크기 조정
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          
          // 고정된 윈도우 크기에 맞춰 컨테이너 크기 설정
          final containerWidth = screenWidth * 0.85; // 약 408px
          final containerHeight = screenHeight * 0.85; // 약 660px
          
          // 로고 크기를 윈도우 크기에 따라 조정 (1.2배 확대)
          final logoSize = (containerWidth * 0.18).clamp(72.0, 120.0);
          
          // 고정된 폰트 크기 사용 (직접 수정 가능)
          const double titleFontSize = 40.0;     // SIGMA 타이틀
          const double subtitleFontSize = 11.0;  // Smart Interactive Gesture, Management Assistant
          const double loginFontSize = 28.0;     // Login 텍스트
          const double buttonFontSize = 16.0;    // 버튼 텍스트
          
          return Container(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Container(
                width: containerWidth,
                height: containerHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 상단 로고 섹션 - 황금비율에 맞춰 조정
                    Container(
                      width: double.infinity,
                      height: containerHeight * 0.3, // 전체 높이의 30%
                      padding: EdgeInsets.all(containerWidth * 0.04),
                      child: _buildHeaderSection(
                        logoSize: logoSize,
                        titleFontSize: titleFontSize,
                        subtitleFontSize: subtitleFontSize,
                        containerWidth: containerWidth,
                      ),
                    ),
                    
                    // 로그인 섹션 - 나머지 공간 사용
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.all(containerWidth * 0.04),
                        padding: EdgeInsets.all(containerWidth * 0.06),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EEFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _buildLoginSection(
                          context: context,
                          loginFontSize: loginFontSize,
                          buttonFontSize: buttonFontSize,
                          containerWidth: containerWidth,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection({
    required double logoSize,
    required double titleFontSize,
    required double subtitleFontSize,
    required double containerWidth,
  }) {
    // 로고와 텍스트를 항상 가로로 배치하고 가운데 정렬
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 로고
          Container(
            width: logoSize,
            height: logoSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(logoSize / 2),
              child: Image.asset(
                'assets/images/sigma_logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4),
                      borderRadius: BorderRadius.circular(logoSize / 2),
                    ),
                    child: Icon(
                      Icons.gesture,
                      color: Colors.white,
                      size: logoSize * 0.5,
                    ),
                  );
                },
              ),
            ),
          ),
          
          SizedBox(width: containerWidth * 0.06),
          
          // 타이틀 섹션
          _buildTitleSection(titleFontSize, subtitleFontSize),
        ],
      ),
    );
  }

  Widget _buildTitleSection(double titleFontSize, double subtitleFontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Smart Interactive Gesture 텍스트
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: subtitleFontSize,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            children: [
              TextSpan(
                text: 'S',
                style: TextStyle(color: Color(0xFF0004FF)),
              ),
              TextSpan(
                text: 'mart ',
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: 'I',
                style: TextStyle(color: Color(0xFF0004FF)),
              ),
              TextSpan(
                text: 'nteractive ',
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: 'G',
                style: TextStyle(color: Color(0xFF0004FF)),
              ),
              TextSpan(
                text: 'esture',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
        
        SizedBox(height: titleFontSize * 0.1),
        
        // SIGMA 메인 타이틀
        Text(
          'SIGMA',
          style: GoogleFonts.inter(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            height: 1.0,
          ),
        ),
        
        SizedBox(height: titleFontSize * 0.1),
        
        // Management Assistant 텍스트 - 오른쪽으로 이동
        Padding(
          padding: EdgeInsets.only(left: 72.0), // 왼쪽 패딩 추가로 오른쪽으로 이동
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              children: [
                TextSpan(
                  text: 'M',
                  style: TextStyle(color: Color(0xFF0004FF)),
                ),
                TextSpan(
                  text: 'anagement ',
                  style: TextStyle(color: Colors.black),
                ),
                TextSpan(
                  text: 'A',
                  style: TextStyle(color: Color(0xFF0004FF)),
                ),
                TextSpan(
                  text: 'ssistant',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginSection({
    required BuildContext context,
    required double loginFontSize,
    required double buttonFontSize,
    required double containerWidth,
  }) {
    return Column(
      children: [
        SizedBox(height: loginFontSize * 0.5),
        
        // Login 타이틀
        Text(
          'Login',
          style: GoogleFonts.roboto(
            fontSize: loginFontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2981),
            height: 1.0,
          ),
        ),
        
        SizedBox(height: loginFontSize * 1.5),
        
        // Google 로그인 버튼
        Container(
          width: containerWidth * 0.8, // 전체 너비가 아닌 80%로 제한
          height: (containerWidth * 0.1).clamp(50.0, 60.0),
          child: ElevatedButton(
            onPressed: () {
              _handleGoogleLogin(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[700],
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google 로고 이미지 (1.2배 확대)
                Image.asset(
                  'assets/images/google_logo.png',
                  width: buttonFontSize * 1.56, // 1.3 * 1.2 = 1.56
                  height: buttonFontSize * 1.56,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: buttonFontSize * 1.56, // 1.2배 확대
                      height: buttonFontSize * 1.56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4285F4),
                        borderRadius: BorderRadius.circular(buttonFontSize * 0.78), // 0.65 * 1.2
                      ),
                      child: Icon(
                        Icons.g_mobiledata,
                        color: Colors.white,
                        size: buttonFontSize,
                      ),
                    );
                  },
                ),
                SizedBox(width: buttonFontSize * 0.8),
                Text(
                  'Continue with Google',
                  style: GoogleFonts.roboto(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
        
      ],
    );
  }


  void _handleGoogleLogin(BuildContext context) {
    // 로딩 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginLoadingScreen()),
    );
  }
}

// Figma Node ID: 1-6 (로그인 로딩 화면)
class LoginLoadingScreen extends StatefulWidget {
  const LoginLoadingScreen({super.key});

  @override
  State<LoginLoadingScreen> createState() => _LoginLoadingScreenState();
}

class _LoginLoadingScreenState extends State<LoginLoadingScreen> {
  // 임시로 사용자 등록 상태를 추적하는 정적 변수
  static bool _isUserRegistered = false;
  
  @override
  void initState() {
    super.initState();
    // 실제 OAuth 요청 대신 시뮬레이션
    _simulateGoogleOAuth();
  }

  Future<void> _simulateGoogleOAuth() async {
    // TODO: 실제 Google OAuth API 호출
    // 현재는 시뮬레이션만 수행
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      // 사용자 등록 상태에 따라 화면 분기
      if (_isUserRegistered) {
        // 기존 사용자 - 얼굴 인증 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FaceRegistrationScreen()),
        );
      } else {
        // 신규 사용자 - 얼굴 등록 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FaceEnrollmentScreen()),
        );
      }
    }
  }
  
  // 사용자 등록 완료 시 호출할 정적 메소드
  static void setUserRegistered() {
    _isUserRegistered = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          
          // 고정된 윈도우 크기에 맞춰 컨테이너 크기 설정
          final containerWidth = screenWidth * 0.85; // 약 408px
          final containerHeight = screenHeight * 0.85; // 약 660px
          
          // 로고 크기를 윈도우 크기에 따라 조정 (1.2배 확대)
          final logoSize = (containerWidth * 0.18).clamp(72.0, 120.0);
          
          // 고정된 폰트 크기 사용 (직접 수정 가능)
          const double titleFontSize = 40.0;     // SIGMA 타이틀
          const double subtitleFontSize = 11.0;  // Smart Interactive Gesture, Management Assistant
          const double loadingFontSize = 28.0;   // 로그인 중입니다 텍스트
          
          return Container(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Container(
                width: containerWidth,
                height: containerHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 상단 로고 섹션 - 로그인 화면과 동일
                    Container(
                      width: double.infinity,
                      height: containerHeight * 0.3, // 전체 높이의 30%
                      padding: EdgeInsets.all(containerWidth * 0.04),
                      child: _buildHeaderSection(
                        logoSize: logoSize,
                        titleFontSize: titleFontSize,
                        subtitleFontSize: subtitleFontSize,
                        containerWidth: containerWidth,
                      ),
                    ),
                    
                    // 로딩 섹션
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.all(containerWidth * 0.04),
                        padding: EdgeInsets.all(containerWidth * 0.06),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EEFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 로딩 인디케이터
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2E2981),
                              ),
                              strokeWidth: 3.0,
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // 로그인 중입니다 텍스트
                            Text(
                              '-로그인 중입니다-',
                              style: GoogleFonts.roboto(
                                fontSize: loadingFontSize,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E2981),
                                height: 1.0,
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // 설명 텍스트
                            Text(
                              'Google 계정으로 인증 중...',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 헤더 섹션은 로그인 화면과 동일
  Widget _buildHeaderSection({
    required double logoSize,
    required double titleFontSize,
    required double subtitleFontSize,
    required double containerWidth,
  }) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 로고
          Container(
            width: logoSize,
            height: logoSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(logoSize / 2),
              child: Image.asset(
                'assets/images/sigma_logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4),
                      borderRadius: BorderRadius.circular(logoSize / 2),
                    ),
                    child: Icon(
                      Icons.gesture,
                      color: Colors.white,
                      size: logoSize * 0.5,
                    ),
                  );
                },
              ),
            ),
          ),
          
          SizedBox(width: containerWidth * 0.06),
          
          // 타이틀 섹션
          _buildTitleSection(titleFontSize, subtitleFontSize),
        ],
      ),
    );
  }

  Widget _buildTitleSection(double titleFontSize, double subtitleFontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Smart Interactive Gesture 텍스트
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: subtitleFontSize,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            children: [
              TextSpan(
                text: 'S',
                style: TextStyle(color: Color(0xFF0004FF)),
              ),
              TextSpan(
                text: 'mart ',
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: 'I',
                style: TextStyle(color: Color(0xFF0004FF)),
              ),
              TextSpan(
                text: 'nteractive ',
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: 'G',
                style: TextStyle(color: Color(0xFF0004FF)),
              ),
              TextSpan(
                text: 'esture',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
        
        SizedBox(height: titleFontSize * 0.1),
        
        // SIGMA 메인 타이틀
        Text(
          'SIGMA',
          style: GoogleFonts.inter(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            height: 1.0,
          ),
        ),
        
        SizedBox(height: titleFontSize * 0.1),
        
        // Management Assistant 텍스트 - 오른쪽으로 이동
        Padding(
          padding: EdgeInsets.only(left: 72.0), // 왼쪽 패딩 추가로 오른쪽으로 이동
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              children: [
                TextSpan(
                  text: 'M',
                  style: TextStyle(color: Color(0xFF0004FF)),
                ),
                TextSpan(
                  text: 'anagement ',
                  style: TextStyle(color: Colors.black),
                ),
                TextSpan(
                  text: 'A',
                  style: TextStyle(color: Color(0xFF0004FF)),
                ),
                TextSpan(
                  text: 'ssistant',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Figma Node ID: 1-8 (얼굴 인증 화면 - 기존 사용자용)
class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  bool _isCameraReady = false;
  bool _isPhotoCaptured = false; // 촬영 완료 상태 추가

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // TODO: 카메라 초기화 구현
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isCameraReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 상단 헤더
            _buildHeader(),
            
            const SizedBox(height: 40),
            
            // 메인 컨텐츠
            Expanded(
              child: Column(
                children: [
                  // 얼굴 인증하기 제목
                  _buildTitle(),
                  
                  const SizedBox(height: 30),
                  
                  // 카메라 영역
                  Expanded(
                    child: _buildCameraArea(),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // 촬영하기 버튼 또는 인증하기/다시찍기 버튼
                  _buildActionButtons(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Back 버튼
        Container(
          width: 120,
          height: 47,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 3,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back_ios, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTitle() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFFB6A0F3),
        borderRadius: BorderRadius.circular(27.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 왼쪽 화살표
          const Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: 30,
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: 30,
          ),
          
          const SizedBox(width: 20),
          
          // 제목 텍스트
          Text(
            '얼굴 인증하기',
            style: GoogleFonts.roboto(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(width: 20),
          
          // 오른쪽 화살표
          Transform.rotate(
            angle: 3.14159, // 180도 회전
            child: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 30,
            ),
          ),
          Transform.rotate(
            angle: 3.14159, // 180도 회전
            child: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraArea() {
    return Container(
      width: 350,
      height: 350,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF3B82F6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: _isCameraReady
            ? _buildCameraPreview()
            : _buildCameraPlaceholder(),
      ),
    );
  }

  Widget _buildCameraPreview() {
    // TODO: 실제 카메라 프리뷰 구현
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF8F9FA),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face_retouching_natural,
              size: 80,
              color: Color(0xFF6B7280),
            ),
            SizedBox(height: 10),
            Text(
              '카메라 프리뷰',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 5),
            Text(
              '얼굴을 원 안에 맞춰주세요',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF1F5F9),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              strokeWidth: 3.0,
            ),
            SizedBox(height: 20),
            Text(
              '카메라 준비 중...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    // 촬영 전: 촬영하기 버튼만 표시
    if (!_isPhotoCaptured) {
      return Container(
        width: 295,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFCADDFF),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isCameraReady ? _handleTakePhoto : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCADDFF),
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            '촬영하기',
            style: GoogleFonts.roboto(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      );
    }
    
    // 촬영 후: 인증하기/다시찍기 버튼 표시 (분리된 두 개 버튼)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 인증하기 버튼 (왼쪽)
        Container(
          width: 145,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFCADDFF),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 3,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _handleAuthenticate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCADDFF),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              '인증하기',
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12), // 버튼 사이 간격 확대
        
        // 다시찍기 버튼 (오른쪽)
        Container(
          width: 145,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFCADDFF),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 3,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _handleRetake,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCADDFF),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              '다시찍기',
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleTakePhoto() {
    // TODO: 실제 카메라 촬영 기능 구현
    // 현재는 시뮬레이션으로 상태만 변경
    setState(() {
      _isPhotoCaptured = true;
    });
    
    // 촬영 완료 메시지 표시 (선택사항)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('얼굴 촬영이 완료되었습니다'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  void _handleAuthenticate() {
    // TODO: AWS Rekognition을 통한 얼굴 인증 처리
    // 성공 시뮬레이션을 위해 바로 성공 팝업 표시
    _showAuthenticationSuccessDialog();
  }
  
  // Figma Node ID: 3-511 (얼굴 인증 실패 팝업)
  void _showAuthenticationFailureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 배경 터치로 닫기 방지
      barrierColor: const Color(0xFF0C0C0C).withOpacity(0.75), // Figma의 투명 배경
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 457,
          height: 235,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F4),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9397B8).withOpacity(0.15),
                blurRadius: 9,
                spreadRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 닫기 버튼 (우상단)
              Positioned(
                top: 10,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF4B4B4B),
                    ),
                  ),
                ),
              ),
              
              // 메인 컨텐츠
              Positioned.fill(
                left: 8,
                right: 8,
                top: 16,
                bottom: 16,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // X 아이콘 (실패)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53E3E), // 빨간색 X 배경
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // 실패 메시지
                    Text(
                      '얼굴 인증에 실패했습니다!',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B4B4B),
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // OK 버튼
                    Container(
                      width: 72,
                      height: 27,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // 실패 시에는 다시 촬영할 수 있도록 상태 초기화
                          setState(() {
                            _isPhotoCaptured = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF185ABD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
                        ),
                        child: Text(
                          'OK',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Figma Node ID: 3-328 (얼굴 인증 성공 팝업)
  void _showAuthenticationSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 배경 터치로 닫기 방지
      barrierColor: const Color(0xFF0C0C0C).withOpacity(0.75), // Figma의 투명 배경
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 457,
          height: 235,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F4),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9397B8).withOpacity(0.15),
                blurRadius: 9,
                spreadRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 닫기 버튼 (우상단)
              Positioned(
                top: 10,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF4B4B4B),
                    ),
                  ),
                ),
              ),
              
              // 메인 컨텐츠
              Positioned.fill(
                left: 8,
                right: 8,
                top: 16,
                bottom: 16,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 체크 아이콘
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50), // 초록색 체크 배경
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // 성공 메시지
                    Text(
                      '얼굴 인증에 성공했습니다!',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B4B4B),
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // OK 버튼
                    Container(
                      width: 72,
                      height: 27,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // 인증 성공 시 메인 페이지로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF185ABD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
                        ),
                        child: Text(
                          'OK',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRetake() {
    // 다시 촬영을 위해 상태를 초기화
    setState(() {
      _isPhotoCaptured = false;
    });
    
    // 다시 촬영 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('다시 촬영할 수 있습니다'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }
}

// Figma Node ID: 1-347 (얼굴 등록 화면 - 신규 사용자용)
class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  bool _isCameraReady = false;
  bool _isPhotoCaptured = false; // 촬영 완료 상태 추가

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // TODO: 카메라 초기화 구현
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isCameraReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 상단 헤더
            _buildHeader(),
            
            const SizedBox(height: 40),
            
            // 메인 컨텐츠
            Expanded(
              child: Column(
                children: [
                  // 얼굴 등록하기 제목
                  _buildTitle(),
                  
                  const SizedBox(height: 30),
                  
                  // 카메라 영역
                  Expanded(
                    child: _buildCameraArea(),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // 촬영하기 버튼 또는 등록하기/다시찍기 버튼
                  _buildActionButtons(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Back 버튼
        Container(
          width: 120,
          height: 47,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 3,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back_ios, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTitle() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFFB6A0F3),
        borderRadius: BorderRadius.circular(27.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 왼쪽 화살표
          const Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: 30,
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: 30,
          ),
          
          const SizedBox(width: 20),
          
          // 제목 텍스트 - "얼굴 등록하기"
          Text(
            '얼굴 등록하기',
            style: GoogleFonts.roboto(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(width: 20),
          
          // 오른쪽 화살표
          Transform.rotate(
            angle: 3.14159, // 180도 회전
            child: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 30,
            ),
          ),
          Transform.rotate(
            angle: 3.14159, // 180도 회전
            child: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraArea() {
    return Container(
      width: 350,
      height: 350,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF3B82F6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: _isCameraReady
            ? _buildCameraPreview()
            : _buildCameraPlaceholder(),
      ),
    );
  }

  Widget _buildCameraPreview() {
    // TODO: 실제 카메라 프리뷰 구현
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF8F9FA),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face_retouching_natural,
              size: 80,
              color: Color(0xFF6B7280),
            ),
            SizedBox(height: 10),
            Text(
              '카메라 프리뷰',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 5),
            Text(
              '얼굴을 원 안에 맞춰주세요',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF1F5F9),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              strokeWidth: 3.0,
            ),
            SizedBox(height: 20),
            Text(
              '카메라 준비 중...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    // 촬영 전: 촬영하기 버튼만 표시
    if (!_isPhotoCaptured) {
      return Container(
        width: 295,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFCADDFF),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isCameraReady ? _handleTakePhoto : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCADDFF),
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            '촬영하기',
            style: GoogleFonts.roboto(
              fontSize: 20, // Figma에서 더 큰 폰트 사이즈
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      );
    }
    
    // 촬영 후: 등록하기/다시찍기 버튼 표시 (분리된 두 개 버튼)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 등록하기 버튼 (왼쪽)
        Container(
          width: 145,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFCADDFF),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 3,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCADDFF),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              '등록하기',
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12), // 버튼 사이 간격
        
        // 다시찍기 버튼 (오른쪽)
        Container(
          width: 145,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFCADDFF),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 3,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _handleRetake,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCADDFF),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              '다시찍기',
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleTakePhoto() {
    // TODO: 실제 카메라 촬영 기능 구현
    // 현재는 시뮬레이션으로 상태만 변경
    setState(() {
      _isPhotoCaptured = true;
    });
    
    // 촬영 완료 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('얼굴 촬영이 완료되었습니다'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  void _handleRegister() {
    // TODO: AWS Rekognition을 통한 얼굴 등록 처리
    // 성공 시뮬레이션을 위해 바로 성공 팝업 표시
    _showEnrollmentSuccessDialog();
  }

  void _handleRetake() {
    // 다시 촬영을 위해 상태를 초기화
    setState(() {
      _isPhotoCaptured = false;
    });
    
    // 다시 촬영 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('다시 촬영할 수 있습니다'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  // Figma Node ID: 3-328 (얼굴 등록 성공 팝업)
  void _showEnrollmentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 배경 터치로 닫기 방지
      barrierColor: const Color(0xFF0C0C0C).withOpacity(0.75), // Figma의 투명 배경
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 457,
          height: 235,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F4),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9397B8).withOpacity(0.15),
                blurRadius: 9,
                spreadRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 닫기 버튼 (우상단)
              Positioned(
                top: 10,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF4B4B4B),
                    ),
                  ),
                ),
              ),
              
              // 메인 컨텐츠
              Positioned.fill(
                left: 8,
                right: 8,
                top: 16,
                bottom: 16,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 체크 아이콘 (성공)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50), // 초록색 체크 배경
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // 성공 메시지
                    Text(
                      '얼굴 인증에 성공했습니다!',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B4B4B),
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // OK 버튼
                    Container(
                      width: 72,
                      height: 27,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // 등록 완료 시 사용자 등록 상태 업데이트
                          _LoginLoadingScreenState.setUserRegistered();
                          // 등록 완료 후 로그인 화면으로 돌아가기
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF185ABD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
                        ),
                        child: Text(
                          'OK',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Figma Node ID: 3-511 (얼굴 등록 실패 팝업)
  void _showEnrollmentFailureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 배경 터치로 닫기 방지
      barrierColor: const Color(0xFF0C0C0C).withOpacity(0.75), // Figma의 투명 배경
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 457,
          height: 235,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F4),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9397B8).withOpacity(0.15),
                blurRadius: 9,
                spreadRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 닫기 버튼 (우상단)
              Positioned(
                top: 10,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF4B4B4B),
                    ),
                  ),
                ),
              ),
              
              // 메인 컨텐츠
              Positioned.fill(
                left: 8,
                right: 8,
                top: 16,
                bottom: 16,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // X 아이콘 (실패)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53E3E), // 빨간색 X 배경
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // 실패 메시지
                    Text(
                      '얼굴 인증에 실패했습니다!',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B4B4B),
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // OK 버튼
                    Container(
                      width: 72,
                      height: 27,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // 실패 시에는 다시 촬영할 수 있도록 상태 초기화
                          setState(() {
                            _isPhotoCaptured = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF185ABD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
                        ),
                        child: Text(
                          'OK',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Figma Node ID: 1-523 (메인 페이지 - 얼굴 인증 성공 후)
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          
          // 고정된 윈도우 크기에 맞춰 컨테이너 크기 설정
          final containerWidth = screenWidth * 0.85;
          final containerHeight = screenHeight * 0.85;
          
          return Container(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Container(
                width: containerWidth,
                height: containerHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      spreadRadius: 3,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 3,
                      spreadRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 상단 헤더 바
                    Positioned(
                      top: 21,
                      left: 17,
                      child: Container(
                        width: containerWidth * 0.92, // 626px 상대 크기
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6186FF),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 3,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // 프로필 아이콘 배경 원 (왼쪽)
                            Positioned(
                              left: 17,
                              top: 9,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFFFFF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            
                            // 프로필 아이콘
                            Positioned(
                              left: 12,
                              top: 4,
                              child: Container(
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.account_circle,
                                  size: 50,
                                  color: Color(0xFF0D0D11),
                                ),
                              ),
                            ),
                            
                            // AWS님 텍스트
                            Positioned(
                              left: 68,
                              top: 10,
                              child: Text(
                                'AWS님',
                                style: GoogleFonts.roboto(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            
                            // 설정 아이콘 (오른쪽)
                            Positioned(
                              right: 14,
                              top: 7,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                  );
                                },
                                child: Container(
                                  width: 45,
                                  height: 45,
                                  child: const Icon(
                                    Icons.settings,
                                    size: 30,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // FREE 텍스트
                    Positioned(
                      left: 32,
                      top: 75,
                      child: Text(
                        'FREE',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.67,
                        ),
                      ),
                    ),
                    
                    // 트레킹 시작하기 버튼 (메인)
                    Positioned(
                      left: containerWidth * 0.2, // 146px 상대 크기
                      top: 234,
                      child: Container(
                        width: containerWidth * 0.57, // 392px 상대 크기
                        height: 103,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D11),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 3,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: 트레킹 화면으로 이동
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('트레킹 기능은 곧 구현됩니다'),
                                backgroundColor: Color(0xFF6186FF),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D0D11),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: Text(
                            '트레킹 시작하기',
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Log out 버튼 (하단 오른쪽)
                    Positioned(
                      right: 15,
                      bottom: 16,
                      child: Container(
                        width: 190,
                        height: 51,
                        decoration: BoxDecoration(
                          color: const Color(0xFF677BFF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFF4E66FF),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 3,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            // 로그아웃 - 로그인 화면으로 돌아가기
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF677BFF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Log out',
                                style: GoogleFonts.roboto(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Transform.rotate(
                                angle: 3.14159, // 180도 회전
                                child: Transform.scale(
                                  scaleY: -1, // Y축 반전
                                  child: const Icon(
                                    Icons.arrow_back_ios,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Figma Node ID: 1-1338 (설정 페이지)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 설정값들
  String _leftClickGesture = '선택 안함';
  String _rightClickGesture = '오른손을 모두 펴고';
  String _wheelScrollGesture = 'text';
  String _recordStartGesture = 'text';
  String _recordStopGesture = 'text';
  
  bool _showMouseCursor = true;
  bool _useLeftHand = false;
  bool _showSkeleton = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          
          // 고정된 윈도우 크기에 맞춰 컨테이너 크기 설정
          final containerWidth = screenWidth * 0.85;
          final containerHeight = screenHeight * 0.85;
          
          return Container(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Container(
                width: containerWidth,
                height: containerHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      spreadRadius: 3,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 3,
                      spreadRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 상단 제목과 Back 버튼
                    Positioned(
                      top: 40,
                      left: 45,
                      child: Row(
                        children: [
                          // 설정 아이콘
                          Container(
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.settings,
                              size: 35,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Setting 텍스트
                          Text(
                            'Setting',
                            style: GoogleFonts.roboto(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Back 버튼 (우상단)
                    Positioned(
                      top: 16,
                      right: 14,
                      child: Container(
                        width: 107,
                        height: 35,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6186FF),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6186FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Back',
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // 구분선
                    Positioned(
                      top: 106,
                      left: 18,
                      child: Container(
                        width: 634,
                        height: 1.4,
                        color: Colors.grey[300],
                      ),
                    ),
                    
                    // 손동작 섹션 (왼쪽)
                    Positioned(
                      top: 124,
                      left: 87,
                      child: _buildGestureSection(),
                    ),
                    
                    // 화면 섹션 (오른쪽)
                    Positioned(
                      top: 121,
                      right: 87,
                      child: _buildScreenSection(),
                    ),
                    
                    // 세로 구분선
                    Positioned(
                      top: 143,
                      left: 339,
                      child: Container(
                        width: 1,
                        height: 292,
                        color: Colors.grey[300],
                      ),
                    ),
                    
                    // 저장하기 버튼 (하단)
                    Positioned(
                      bottom: 68,
                      left: 288,
                      child: Container(
                        width: 95,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF88AEFF),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('설정이 저장되었습니다'),
                                backgroundColor: Color(0xFF6186FF),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF88AEFF),
                            foregroundColor: const Color(0xFF070F27),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            '저장하기',
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF070F27),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGestureSection() {
    return Container(
      width: 158,
      child: Column(
        children: [
          // 손동작 헤더
          Container(
            width: 158,
            height: 27,
            decoration: const BoxDecoration(
              color: Color(0xFFB6A0F3),
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(12),
                right: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                '손동작',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // 좌클릭
          _buildGestureRow('좌클릭', _leftClickGesture, (value) {
            setState(() {
              _leftClickGesture = value;
            });
          }),
          
          const SizedBox(height: 20),
          
          // 우클릭
          _buildGestureRow('우클릭', _rightClickGesture, (value) {
            setState(() {
              _rightClickGesture = value;
            });
          }),
          
          const SizedBox(height: 20),
          
          // 휠스크롤
          _buildGestureRow('휠스크롤', _wheelScrollGesture, (value) {
            setState(() {
              _wheelScrollGesture = value;
            });
          }),
          
          const SizedBox(height: 20),
          
          // 녹음 시작
          _buildGestureRow('녹음 시작', _recordStartGesture, (value) {
            setState(() {
              _recordStartGesture = value;
            });
          }),
          
          const SizedBox(height: 20),
          
          // 녹음 중지
          _buildGestureRow('녹음 중지', _recordStopGesture, (value) {
            setState(() {
              _recordStopGesture = value;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildScreenSection() {
    return Container(
      width: 208,
      child: Column(
        children: [
          // 화면 헤더
          Container(
            width: 158,
            height: 27,
            decoration: const BoxDecoration(
              color: Color(0xFFB6A0F3),
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(12),
                right: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                '화면',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 마우스 커서 표시
          _buildToggleRow('마우스 커서 표시', _showMouseCursor, (value) {
            setState(() {
              _showMouseCursor = value;
            });
          }),
          
          const SizedBox(height: 30),
          
          // 왼손 사용
          _buildToggleRow('왼손 사용', _useLeftHand, (value) {
            setState(() {
              _useLeftHand = value;
            });
          }),
          
          const SizedBox(height: 30),
          
          // 스켈레톤 표시
          _buildToggleRow('스켈레톤 표시', _showSkeleton, (value) {
            setState(() {
              _showSkeleton = value;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildGestureRow(String label, String value, Function(String) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 83,
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF070F27),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 164,
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: value == '선택 안함' ? const Color(0xFFA0A0A0) : const Color(0xFF7DAEF3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.black,
              ),
              items: [
                '선택 안함',
                '오른손을 모두 펴고',
                'text',
              ].map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: item == '선택 안함' ? const Color(0xFF040F0F) : Colors.black,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF070F27),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Container(
          width: 50,
          height: 22,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF313C73),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF7F7F7F),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
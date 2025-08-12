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

// Google OAuth 로그인 로딩 화면
class LoginLoadingScreen extends StatefulWidget {
  const LoginLoadingScreen({super.key});

  @override
  State<LoginLoadingScreen> createState() => _LoginLoadingScreenState();
}

class _LoginLoadingScreenState extends State<LoginLoadingScreen> {
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
      // 로그인 성공 시뮬레이션 - 신규 사용자라서 얼굴 등록 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FaceRegistrationScreen()),
      );
    }
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

// 얼굴 등록 화면
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
                          // TODO: 다음 화면으로 이동
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